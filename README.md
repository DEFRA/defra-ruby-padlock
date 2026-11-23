# DefraRuby::Padlock

![Build Status](https://github.com/DEFRA/defra-ruby-padlock/workflows/CI/badge.svg)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-ruby-padlock&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=DEFRA_defra-ruby-padlock)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-ruby-padlock&metric=coverage)](https://sonarcloud.io/dashboard?id=DEFRA_defra-ruby-padlock)
[![Licence](https://img.shields.io/badge/Licence-OGLv3-blue.svg)](http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3)

Ruby client for the Storm Padlock API.

Padlock takes card details during a Storm call and submits them to GOV.UK Pay. The caller enters the card number and security code on their phone keypad, so the agent never hears or sees them. The agent enters the name on the card and its end date in Storm DTA. This gem asks Padlock to start that card capture for a GOV.UK Pay MOTO payment and reads back the result.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Usage](#usage)
4. [Error Handling](#error-handling)
5. [Testing](#testing)

## Installation

The gem is not published to RubyGems yet. Until it is, add it to your application's Gemfile from the GitHub repository, once that exists:

```ruby
gem "defra_ruby_padlock", git: "https://github.com/DEFRA/defra-ruby-padlock"
```

And then execute

```sh
bundle install
```

## Configuration

```ruby
# config/initializers/defra_ruby_padlock.rb
require "defra_ruby/padlock"

DefraRuby::Padlock.configure do |config|
  config.padlock_api_username = ENV.fetch("PADLOCK_USERNAME")
  config.padlock_api_password = ENV.fetch("PADLOCK_PASSWORD")
  config.lock_interface = "WEXTest"
end
```

`lock_interface` is the name of the lock interface set up for your service in Storm.

`padlock_url` defaults to `https://apigateway.timeforstorm.com/StormWebServices` and only needs setting to point the gem somewhere else.

## Usage

The gem provides 4 services a host app can use:

- DefraRuby::Padlock::UserDetailsService
- DefraRuby::Padlock::BuildPaymentRequestBodyService
- DefraRuby::Padlock::InitiatePaymentService
- DefraRuby::Padlock::PaymentDetailsService

It requests a Padlock access token when one is first needed and reuses it until it expires.

Starting a payment takes two calls: build the request body, then send it. The body needs the agent's Storm user ID, which the User Details Service looks up.

### User Details Service

Looks up a Storm user by their email address, which is their Storm username.

```ruby
user = DefraRuby::Padlock::UserDetailsService.run(email: "test.agent@example.gov.uk")

#<DefraRuby::Padlock::UserResponse:0x00007f6b9a3c5160
 @first_name="Test",
 @last_name="Agent",
 @organisation=1234,
 @user_id=123456,
 @username="test.agent@example.gov.uk">

user.user_id # => 123456
```

The lookup is not case sensitive. For an email Padlock does not know it responds with HTTP 403, which is raised as a DefraRuby::Padlock::ApiError.

### Build Payment Request Body Service

Before calling this, create the payment in GOV.UK Pay with `moto: true` and `authorisation_mode: "moto_api"`. Its response supplies the `payment_id` and the one-time token.

```ruby
body = DefraRuby::Padlock::BuildPaymentRequestBodyService.run(
  user_id: 123_456,
  amount: 1567,
  payment_id: "testpaymentid0000000000001",
  one_time_token: "00000000-0000-0000-0000-000000000000",
  transaction_reference: "wex-test-transaction-001",
  description: "Payment for WEX000001 registration"
)

{
  userId: 123456,
  lockInterface: "WEXTest",
  checkUserReadyForPayment: false,
  validateCardInformation: true,
  padlockData: {
    transactionAmount: { value: "15.67", readonly: true },
    reference: { value: "testpaymentid0000000000001", readonly: true },
    oneTimeToken: { value: "00000000-0000-0000-0000-000000000000" },
    TransactionReference: { value: "wex-test-transaction-001", readonly: true },
    Description: { value: "Payment for WEX000001 registration", readonly: true }
  }
}
```

| Argument | Value |
| --- | --- |
| `user_id` | The Storm user ID of the agent taking the call, from the User Details Service |
| `amount` | The amount in pence, as sent to GOV.UK Pay. Padlock is sent pounds (`"15.67"`) |
| `payment_id` | The GOV.UK Pay `payment_id` |
| `one_time_token` | `_links.auth_url_post.params.one_time_token` from the GOV.UK Pay response |
| `transaction_reference` | The `reference` sent to GOV.UK Pay |
| `description` | The `description` sent to GOV.UK Pay |

The service makes no request. The result is a plain hash, so it can be changed before it is sent.

### Initiate Payment Service

```ruby
DefraRuby::Padlock::InitiatePaymentService.run(body: body)

true
```

The body is sent to Padlock as given. On success the Padlock panel opens for the agent in Storm DTA.

Each GOV.UK Pay one-time token can be used once. To try again, create a new GOV.UK Pay payment.

### Payment Details Service

```ruby
DefraRuby::Padlock::PaymentDetailsService.run(payment_id: "testpaymentid0000000000002")

#<DefraRuby::Padlock::PaymentResponse:0x00007f6b9a3c5160
 @payment_reference="testpaymentid0000000000002",
 @results=
  [{"paymentResult"=>"Authorised",
    "transactionTime"=>"2026-01-01 12:00:00",
    "authCode"=>"",
    "paymentProviderRef"=>"testpaymentid0000000000002",
    "transactionAttempt"=>1}]>
```

`results` has one entry for each payment attempt, as returned by Padlock. A successful payment has `paymentResult` `Authorised`.

## Error Handling

HTTP error responses and timeouts from Padlock are raised as DefraRuby::Padlock::ApiError. So are redirects: the gem does not follow them, so that your credentials and access token are never sent to another address.

The message includes the HTTP method and endpoint path. For an HTTP error it also includes the status and Padlock's response body, verbatim; for a timeout there is no status or body. The gem leaves the outgoing headers, query parameters and request body out of the message.

Because the response body is passed through as Padlock sent it, check what it contains before writing the message somewhere others can read it. Here's an example of how you can handle errors:

```ruby
begin
  DefraRuby::Padlock::InitiatePaymentService.run(body: body)
rescue DefraRuby::Padlock::ApiError => e
  puts "An error occurred: #{e.message}"
end
```

Failures to connect, such as a DNS lookup failure or a refused connection, are not wrapped, so the example above does not catch them. They are raised as the underlying Ruby error, for example SocketError or Errno::ECONNREFUSED.

## Testing

```
bundle exec rspec
```

## License

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3
