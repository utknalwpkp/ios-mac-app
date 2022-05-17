//
//  CertificateRefreshManager.swift
//  WireGuardiOS Extension
//
//  Created by Jaroslav on 2021-06-28.
//  Copyright © 2021 Proton Technologies AG. All rights reserved.
//

import Foundation
import NetworkExtension

/// Class for making sure there is always up-to-date certificate.
/// After running `start()` for the first time, will start Timer to run a minute before certificates `RefreshTime`.
final class ExtensionCertificateRefreshManager {

    /// Check certificate every this number of seconds
    private let checkInterval: TimeInterval = 2 * 60

    /// Certificate will be refreshed this number of seconds earlier than requested to lessen the possibility of refreshing it by both app and extension.
    /// Its better for this time to be greater than value of `checkInterval`, so check happens at least once during this period.
    private let refreshEarlierBy: TimeInterval = -3 * 60

    private let vpnAuthenticationStorage: VpnAuthenticationStorage
    private let apiService: ExtensionAPIService
    private let workQueue = DispatchQueue(label: "ExtensionCertificateRefreshManager.Timer", qos: .background)

    // Save stop handler for when certificate refresh finishes
    private var stopHandler: (() -> Void)?

    init(storage: Storage, dataTaskFactory: DataTaskFactory, vpnAuthenticationStorage: VpnAuthenticationStorage, keychain: AuthKeychainHandle) {
        self.vpnAuthenticationStorage = vpnAuthenticationStorage
        self.apiService = ExtensionAPIService(storage: storage, dataTaskFactory: dataTaskFactory, keychain: keychain)
    }

    /// Start timer that will check if certificate is due for refresh. First run will be executed asap (but on another thread).
    func start(withNewSession sessionSelector: String? = nil, completionHandler: ((Result<(), Error>) -> Void)? = nil) {
        log.info("Starting ExtensionCertificateRefreshManager.", category: .userCert)

        guard let sessionSelector = sessionSelector else {
            startTimer()
            completionHandler?(.success(()))
            return
        }

        apiService.startSession(withSelector: sessionSelector) { [weak self] result in
            switch result {
            case .success:
                log.info("Session started successfully. Starting certificate timer.")
                self?.startTimer()
                completionHandler?(.success(()))
            case .failure(let error):
                log.error("Encountered error starting session: \(error)")
                completionHandler?(.failure(error))
            }
        }
    }

    /// Stop all activity and call handler when finished
    func stop(handler: (() -> Void)? = nil) {
        workQueue.async {
            log.info("Stoping ExtensionCertificateRefreshManager.", category: .userCert)
            self.stopTimer()
            guard self.certificateRefreshStarted != nil else {
                handler?()
                return
            }
            log.info("Waiting for certificate refresh before declaring ExtensionCertificateRefreshManager as fully stopped.", category: .userCert)
            self.stopHandler = handler
        }
    }
    
    // MARK: - Timer

    private var timer: BackgroundTimer?

    /// Running timers in NE proved to be not very reliable, so we run it every `checkInterval` seconds all the time, to make sure we don't miss the time when certificate has to be refreshed.
    private func startTimer() {
        workQueue.async {
            self.timer = BackgroundTimer(runAt: Date(), repeating: self.checkInterval, queue: self.workQueue) { [weak self] in
                self?.checkCertificatesNow()
            }
        }
    }

    private func stopTimer() {
        self.timer = nil
    }

    // MARK: - Certificate

    private var certificateRefreshStarted: Date? // Using date instead of boolean flag to be able to reset it after the timeout passes
    private let certificateRefreshTimeout: TimeInterval = 3 * 60

    /// Checks certificate refresh time to make sure we don't refresh them too early and too often.
    @objc private func checkCertificatesNow() {
        guard let certificate = vpnAuthenticationStorage.getStoredCertificate() else {
            log.info("No current certificate. Starting refresh.", category: .userCert)
            refreshCertificate()
            return
        }

        let nextRefreshTime = certificate.refreshTime.addingTimeInterval(refreshEarlierBy)
        log.info("Current cert is valid until: \(certificate.validUntil); refresh time: \(certificate.refreshTime). Will be refreshed after: \(nextRefreshTime).", category: .userCert)

        guard nextRefreshTime <= Date() else {
            return
        }

        log.info("Starting certificate refresh.", category: .userCert)
        refreshCertificate()
    }

    /// Does actual certificate refresh with API and saves new certificate using `vpnAuthenticationStorage`.
    /// This code uses `certificateRefreshStarted` to not run more than one refresh at the same time. Please make sure you always call this code on `workQueue`.
    private func refreshCertificate() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(workQueue))
        #endif

        if let certificateRefreshStartedAt = certificateRefreshStarted {
            // `timeIntervalSinceNow` is negative in case the date is in the past, so always in our case.
            if -certificateRefreshStartedAt.timeIntervalSinceNow < certificateRefreshTimeout {
                log.debug("Certificate refresh is in progress. Skipping.", category: .userCert, event: .refreshError, metadata: ["certificateRefreshStarted": "\(certificateRefreshStartedAt)"])
                return
            }

            log.debug("Certificate refresh took too long. Will reset the flag and continue with certificate refresh.", category: .userCert, event: .refreshError)
            certificateRefreshStarted = nil
        }

        guard let currentKeys = vpnAuthenticationStorage.getStoredKeys() else {
            log.error("Can't load current keys. Nothing to refresh. Giving up.", category: .userCert, event: .refreshError)
            certificateRefreshFinished()
            return
        }

        certificateRefreshStarted = Date()
        let features = vpnAuthenticationStorage.getStoredCertificateFeatures()
        apiService.refreshCertificate(publicKey: currentKeys.publicKey.derRepresentation, features: features) { result in
            switch result {
            case .success(let certificate):
                log.debug("Certificate refreshed. Saving to keychain.", category: .userCert)
                self.vpnAuthenticationStorage.store(certificate: VpnCertificateWithFeatures(certificate: certificate, features: features))
                
            case .failure(let error):
                log.error("Failed to refresh certificate through API: \(error)", category: .userCert)
            }
            self.certificateRefreshFinished()
        }
    }
    
    private func certificateRefreshFinished() {
        certificateRefreshStarted = nil
        stopHandler?()
        stopHandler = nil
    }

}

private final class BackgroundTimer {
    
    private let timerSource: DispatchSourceTimer
    private let closure: () -> Void
    
    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .resumed

    init(runAt nextRunTime: Date, repeating: Double, queue: DispatchQueue, _ closure: @escaping () -> Void) {
        self.closure = closure
        timerSource = DispatchSource.makeTimerSource(queue: queue)
        
        timerSource.schedule(deadline: .now() + .seconds(Int(nextRunTime.timeIntervalSinceNow)), repeating: repeating, leeway: .seconds(10)) // We have at least minute before app (if in foreground) may start refreshing cert. So 10 seconds later is ok.
        timerSource.setEventHandler { [weak self] in
            if repeating <= 0 { // Timer should not repeat, so lets suspend it
                self?.timerSource.suspend()
                self?.state = .suspended
            }
            self?.closure()
        }
        timerSource.resume()
        state = .resumed
    }
    
    deinit {
        timerSource.setEventHandler {}
        if state == .suspended {
            timerSource.resume()
        }
        timerSource.cancel()
    }
    
}
