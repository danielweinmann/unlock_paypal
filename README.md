# UnlockMoip [![Code Climate](https://codeclimate.com/github/danielweinmann/unlock_moip.png)](https://codeclimate.com/github/danielweinmann/unlock_moip)

Moip Assinaturas integration with [Unlock](http://github.com/danielweinmann/unlock) recurring crowdfunding platform

## Installation

Add this line to your Unlock application's Gemfile:

    gem 'unlock_moip', github: 'danielweinmann/unlock_moip', branch: 'master'

And then execute:

    $ bundle

## Usage

Add the following line to your application.js, after _require_tree ._

    //= require unlock_moip

Add the following line to your application.css.sass, after all other non-gateway-specific imports:

    @import unlock_moip

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


This project rocks and uses MIT-LICENSE.
