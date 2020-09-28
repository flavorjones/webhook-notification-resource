# Webhook Notification Resource for [Concourse][]

Send notification messages to any webhook from a [Concourse][] CI pipeline.

This resource provides:

* Pre-formatted markdown messages, with colorful icons, for every Concourse job status.
* Integration with [Gitter][] activity feeds.
* Extensible design to easily add support for other webhooks. (See [Contributing](#contributing) for more information.)

  [Gitter]: https://gitter.im
  [Concourse]: https://concourse.ci

[![Join the chat at https://gitter.im/flavorjones/webhook-notifications-resource](https://badges.gitter.im/flavorjones/webhook-notifications-resource.svg)](https://gitter.im/flavorjones/webhook-notifications-resource?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


## Background

[Concourse][] is an open-source continuous thing-doer. It's pretty amazing for CI and for more complicated pipelines, you should check it out.

It's pretty common to want to send notification messages somewhere when a job succeeds or fails. Sometimes it's just an HTTP POST or other similarly simple action. This resource tries to make it easy to have a polished-looking informational message for these simple integrations.

For more information on Concourse Resources:

- [Concourse Resource](https://concourse-ci.org/resources.html) - how to configure and use resources
- [Concourse Resource Types](https://concourse-ci.org/resource-types.html) - how resources work
- [Concourse Resource Directory](https://resource-types.concourse-ci.org/) - a collection of Concourse integrations


## Source Configuration

These parameters go into the `source` fields of the resource.

__Required__

* `adapter`: The name of the service adapter you want to use.
  * Generally these are named after the service they support, and live in [`resource/lib/adapters`](resource/lib/adapters).
  * Valid values are: `GitterActivityFeedAdapter`, `MockTeapot`
* `url`: The target webhook URL.

__Optional__

* `dryrun`: When set to `true`, the resource does not make any HTTP requests. (Defaults to `false`)


## Invocation

### [`check`](https://concourse-ci.org/implementing-resource-types.html#resource-check) and [`in`](https://concourse-ci.org/implementing-resource-types.html#resource-in)

This resource only supports the `put` step, so these are no-ops in this resource.


### [`out`](https://concourse-ci.org/implementing-resource-types.html#resource-out)

[`put`](https://concourse-ci.org/jobs.html#schema.step.put-step.put) will connect to the webhook and send the configured markdown message.


#### Sending Pre-formatted Messages

This resource comes with some standard pre-formatted messages to reflect typical Concourse job status. You can easily send these messages by setting the following parameter:

* `status`: Set to one of the states named below to get a sane, well-formatted message.

Valid `status` values:

* `aborted` will post the contents of [resource/messages/aborted.md](resource/messages/aborted.md?raw=true)
* `errored` will post the contents of [resource/messages/errored.md](resource/messages/errored.md?raw=true)
* `failed` will post the contents of [resource/messages/failed.md](resource/messages/failed.md?raw=true)
* `pending` will post the contents of [resource/messages/pending.md](resource/messages/pending.md?raw=true)
* `started` will post the contents of [resource/messages/started.md](resource/messages/started.md?raw=true)
* `succeeded` will post the contents of [resource/messages/succeeded.md](resource/messages/succeeded.md?raw=true)

Any other value will post the contents of [resource/messages/unknown.md](resource/messages/unknown.md?raw=true).


#### Sending Custom Messages

To send a custom message, exactly one of the following parameters must be present:

* `message`: The markdown-formatted text of the notification to be sent.
* `message_file`: Path to a file containing the markdown-formatted text of the notification to be sent.

Any Concourse [metadata][] in the `message` string or in the text contents of `message_file` will be evaluated prior to sending the message. If the notification text contains newlines then it will be split into multiple IRC message sends.

> `${ATC_EXTERNAL_URL}/teams/${BUILD_TEAM_NAME}/pipelines/${BUILD_PIPELINE_NAME}/jobs/${BUILD_JOB_NAME}/builds/${BUILD_NAME}`

  [metadata]: http://concourse.ci/implementing-resources.html#resource-metadata


## Example usage

Here's how the resource might be configured to send pre-formatted markdown messages to a Gitter channel activity feed in a Concourse pipeline file:

``` yml
resource_types:
- name: webhook-notification
  type: docker-image
  source:
    repository: flavorjones/webhook-notification-resource

resources:
- name: foobar-gitter-channel
  type: webhook-notification
  source:
    adapter: GitterActivityFeedAdapter
    url: ((webhook_url))

jobs:
- name: run-some-tests
  plan:
    - task: run-a-test
      config: { ... }
  on_success: { put: foobar-gitter-channel, params: {status: "succeeded"} }
  on_failure: { put: foobar-gitter-channel, params: {status: "failed"} }
  on_error:   { put: foobar-gitter-channel, params: {status: "errored"} }
  on_abort:   { put: foobar-gitter-channel, params: {status: "aborted"} }
```

And here's how you can configure a custom message:

``` yml
resource_types:
- name: webhook-notification
  type: docker-image
  source:
    repository: flavorjones/webhook-notification-resource

resources:
- name: foobar-gitter-channel
  type: webhook-notification
  source:
    adapter: GitterActivityFeedAdapter
    url: ((webhook_url))

- name: post-a-message-to-gitter
  plan:
  - put: foobar-gitter-channel
    params:
      message: "_This_ is a *markdown* message about [${BUILD_PIPELINE_NAME}/${BUILD_JOB_NAME}/${BUILD_NAME}}](${BUILD_URL})"
```


## Configuration of a Gitter Webhook

See [docs/gitter-create-webhook.md](docs/gitter-create-webhook.md).


## Roadmap

The following features seem like reasonable things to implement, but I just haven't gotten around to them yet. If you'd like to help implement these, please do!

* Connecting via HTTP proxy or tunnel


## Contributing

Pull requests are welcome, as are Github issues opened to discuss bugs or desired features.

### Adding Support For A New Service

If you'd like to integrate with a new service:

1. Fork this repo
2. Run the tests to ensure you're in a good spot (see below)
3. Create a new adapter in `resource/lib/adapters` named after your ClassName in snake_case.
4. Adapters are modules with one public class method: `.post(url_string, message)`
5. Write some tests!

It's totally possible that your adapter might need to be a real class (not just a module) and take additional arguments (like the config params). If so, let's talk!

If you have questions, please reach out! I shipped this in a hurry so this section is definitely not as explanatory as I'd like.


### Development and Running the tests

#### Without a local Ruby environment

Requirements:

* make
* docker

To build an OCI image and run the tests in that image:

``` sh
$ make test
```

This iteration loop is slightly slower than working with a local Ruby environment (~3 seconds on my laptop).


#### With a local Ruby environment

Requirements:

* ruby >= 2.7

``` sh
$ bundle install && bundle exec rake test
```

This iteration loop is slightly faster than working inside a docker container (~1 second on my laptop).


## License

MIT. See the file named [`LICENSE`](LICENSE) in this repository.
