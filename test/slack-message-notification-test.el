;;; slack-message-notification-test.el --- mention notification tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'slack-message-notification)
(require 'slack-message-event)

(ert-deftest slack-test-message-mentioned-full-display-name ()
  "A mention is detected when full display names are enabled."
  (slack-test-setup
    (oset team full-and-display-names t)
    (puthash "U38383838"
             (list :id "U38383838"
                   :name "test-user"
                   :profile (list :real_name_normalized "Real User"
                                  :display_name_normalized "Display User"))
             (oref team users))
    (let ((message (slack-message-create
                    (list :type "message"
                          :ts "1700000000.000001"
                          :user "U11111"
                          :text "Hello <@U38383838>")
                    team
                    channel)))
      (should (slack-message-mentioned-p message team)))))

(ert-deftest slack-test-message-replied-notifies-the-reply ()
  "A message_replied event notifies for the reply, not only the parent."
  (slack-test-setup
    (let* ((reply-ts "1700000000.000002")
           (thread-ts "1700000000.000001")
           (event (slack-create-message-event
                   (list :type "message"
                         :subtype "message_replied"
                         :channel (oref channel id)
                         :message (list :type "message"
                                        :ts reply-ts
                                        :thread_ts thread-ts
                                        :user "U11111"
                                        :text "A reply"))))
           notified)
      (cl-letf (((symbol-function 'slack-room-find)
                 (lambda (_channel _team) channel))
                ((symbol-function 'slack-message-notify)
                 (lambda (message room actual-team)
                   (setq notified (list message room actual-team)))))
        (slack-event-notify event nil team)
        (should notified)
        (should (equal reply-ts (slack-ts (car notified))))
        (should (equal thread-ts (slack-thread-ts (car notified))))))))

;;; slack-message-notification-test.el ends here
