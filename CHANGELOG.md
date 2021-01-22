# Changelog for flavorjones/webhook-notification-resource

## v1.1.0 / 2021-01-22

Features:
- Discord support
- Adapters can extend default message behavior via `.status_message_for`
- The `url` is no longer emitted as output metadata, because it may be sensitive information.


## v1.0.0 / 2020-08-17

Features:
- extracted webhook-specific behavior into an adapter patter for easier extensibility
- renamed as webhook-notification-resource


## v0.1.0 / 2020-08-16

Birthday! (Originally named gitter-notification-resource)
