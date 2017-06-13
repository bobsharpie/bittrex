package Bittrex;

=encoding utf8

=head1 NAME

Bittrex - API wrapper for the L<Bittrex|https://www.bittrex.com> trading platform.

=cut

use strict;
use warnings;

use Carp;
use JSON;
use LWP::UserAgent;
use URI::Query;
use Data::Dumper;
use Digest::SHA qw( hmac_sha512_hex );

# TODO add logging

our $VERSION = '0.1.0';

use constant {
  APIROOT => 'https://bittrex.com/api/v1.1'
};

=head1 SYNOPSIS

  use Bittrex;

  my $bittrex = Bittrex->new();
  my $market_data = $bittrex->getmarkets();

  my $account = Bittrex->new($apikey, $apisecret);
  my $balances = $bittrex->getbalances();

=head1 DESCRIPTION

This is a basic wrapper for the Bittrex API. It will handle API signing using
your specific API keys. All information is exchanged directly with the Bittrex
API service using a secure HTTPS connections.

Unless otherwise specifically stated, each method returns the decoded JSON
object in the C<result> field of the response. If a call fails, the method
returns C<undef>.

Bittrex is a leading cryptocurrency exchange for buying & selling digital
currency. This software assumes no risk and makes no guarantees of performance
on any trades. Any examples provided here are for reference only and do not
imply any recommendations for investment strategies.

Full API documentation can be found here: L<https://bittrex.com/Home/Api>.

=head2 Methods

=over 4

=cut

################################################################################
=item B<new($my_key, $my_secret)>

The key and secret must be registered to your account under API keys. Be sure
to set appropriate permissions based on the actions you intend to perform.
Public actions do not require these values.

=cut

#---------------------------------------
sub new {
  my $class = shift;
  my ($key, $secret) = @_;

  my $ua = LWP::UserAgent->new();

  my $self = {
    key => $key,
    secret => $secret,
    client => $ua
  };

  bless $self, $class;
}

################################################################################
# TODO provide separate method for non-authenticated (public) requests
sub _get {
  my $self = shift;
  my ($path, $params) = @_;

  # setup for api key signature
  if (defined $self->{key}) {
    my $nonce = time;
    $params->{nonce} = $nonce;
    $params->{apikey} = $self->{key};
  }

  # build the request
  my $qq = URI::Query->new($params);
  my $uri = APIROOT . "$path?$qq";
  my $apisign = $self->_apisign($uri);

  my $client = $self->{client};
  my $resp = $client->get($uri, apisign => $apisign);

  unless ($resp->is_success) {
    carp $resp->status_line;
    return undef;
  }

  # TODO improve error handling
  return decode_json $resp->decoded_content;
}

################################################################################
sub _standard_result {
  my ($json) = @_;

  unless ($json) {
    carp 'no data in response';
    return undef;
  }

  unless ($json->{success}) {
    carp $json->{message};
    return undef;
  }

  return $json->{result};
}

################################################################################
sub _apisign {
  my $self = shift;
  my ($uri) = @_;

  # XXX this isn't entirely awesome... it would be nice if there was a way to
  # include the query parameters in this method rather than handling them in
  # another part of the method. not terrible, just seems like it would be more
  # elegant to put all authentication / signing in the same place.

  unless (defined $self->{secret}) {
    return '';
  }

  hmac_sha512_hex($uri, $self->{secret});
}

################################################################################
=item B<getmarkets()>

Used to get the open and available trading markets at Bittrex along with other metadata.

=cut

#---------------------------------------
sub getmarkets {
  my $self = shift;
  my $json = $self->_get('/public/getmarkets');
  return _standard_result($json);
}

################################################################################
=item B<getcurrencies()>

Used to get all supported currencies at Bittrex along with other metadata.

=cut

#---------------------------------------
sub getcurrencies {
  my $self = shift;
  my $json = $self->_get('/public/getcurrencies');
  return _standard_result($json);
}

################################################################################
=item B<getmarketsummaries()>

Used to get the last 24 hour summary of all active exchanges.

=cut

#---------------------------------------
sub getmarketsummaries {
  my $self = shift;
  my $json = $self->_get('/public/getmarketsummaries');
  return _standard_result($json);
}

################################################################################
=item B<getticker($market)>

Used to get the current tick values for a market.

C<market> : (required) a string literal for the market (ex: BTC-LTC)

=cut

#---------------------------------------
sub getticker {
  my $self = shift;
  my ($market) = @_;

  my $json = $self->_get('/public/getticker', {
    market => $market
  });

  return _standard_result($json);
}

################################################################################
=item B<getmarketsummary($market)>

Used to get the last 24 hour summary of a specified exchange.

C<market> : (required) a string literal for the market (ex: BTC-LTC)

=cut

#---------------------------------------
sub getmarketsummary {
  my $self = shift;
  my ($market) = @_;

  my $json = $self->_get('/public/getmarketsummary', {
    market => $market
  });

  return _standard_result($json);
}

################################################################################
=item B<getorderbook()>

Used to get retrieve the orderbook for a given market

C<market> : (required) a string literal for the market (ex: BTC-LTC)
C<type> : (optional) buy, sell or both to identify the type of order book (default: both)
C<depth> : (optional) how deep of an order book to retrieve (default: 20, max: 50)

=cut

#---------------------------------------
sub getorderbook {
  my $self = shift;
  my ($market, $type, $depth) = @_;

  my $json = $self->_get('/public/getorderbook', {
    market => $market,
    type => $type
  });

  return _standard_result($json);
}

################################################################################
=item B<getmarkethistory()>

Used to retrieve the latest trades that have occured for a specific market.

C<market> : (required) a string literal for the market (ex: BTC-LTC)

=cut

#---------------------------------------
sub getmarkethistory {
  my $self = shift;
  my ($market) = @_;

  my $json = $self->_get('/public/getmarkethistory', {
    market => $market
  });

  return _standard_result($json);
}

################################################################################
=item B<buylimit()>

Used to place a buy-limit order in a specific market. Make sure you have the
proper permissions set on your API keys for this call to work.

On success, returns the UUID of the order.

C<market> (required) a string literal for the market (ex: BTC-LTC)
C<quantity> (required) the amount to purchase
C<rate> (required) the rate at which to place the order.

=cut

#---------------------------------------
sub buylimit {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<selllimit()>

Used to place a sell-limit order in a specific market. Make sure you have the
proper permissions set on your API keys for this call to work.

On success, returns the UUID of the order.

C<market> (required) a string literal for the market (ex: BTC-LTC)
C<quantity> (required) the amount to purchase
C<rate> (required) the rate at which to place the order.

=cut

#---------------------------------------
sub selllimit {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<cancel($uuid)>

Used to cancel a buy or sell order.

C<uuid> (required) uuid of buy or sell order

=cut

#---------------------------------------
sub cancel {
  my $self = shift;
  my ($uuid) = @_;

  my $json = $self->_get('/market/cancel', {
    uuid => $uuid
  });

  unless ($json->{success}) {
    carp $json->{message};
    return undef;
  }

  return 1;
}

################################################################################
=item B<getopenorders($market)>

Get all orders that you currently have opened. A specific market can be requested.

C<market> (optional) a string literal for the market (ex: BTC-LTC)

=cut

#---------------------------------------
sub getopenorders {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<getbalances()>

Used to retrieve all balances from your account.

=cut

#---------------------------------------
sub getbalances {
  my $self = shift;
  my $json = $self->_get('/account/getbalances');
  return _standard_result($json);
}

################################################################################
=item B<getbalance($currency)>

Used to retrieve the balance from your account for a specific currency.

C<currency> : (required) a string literal for the currency (ex: LTC)

=cut

#---------------------------------------
sub getbalance {
  my $self = shift;
  my ($currency) = @_;

  my $json = $self->_get('/account/getbalance', {
    currency => $currency
  });

  return _standard_result($json);
}

################################################################################
=item B<getdepositaddress($currency)>

Used to retrieve or generate an address for a specific currency. If one does not
exist, the call will fail and return -1 until one is available.

On success, returns the deposit address as a string.

C<currency> : (required) a string literal for the currency (ex: LTC)

=cut

#---------------------------------------
sub getdepositaddress {
  my $self = shift;
  my ($currency) = @_;

  my $json = $self->_get('/account/getdepositaddress', {
    currency => $currency
  });

  # first check to see if the address is being generated...
  if ($json->{message} eq 'ADDRESS_GENERATING') {
    return -1;
  }

  # bail out if the call failed
  unless ($json->{success}) {
    carp $json->{message};
    return undef;
  }

  my $result = $json->{result};

  # just some sanity checking...
  unless ($result->{Currency} eq $currency) {
    carp 'returned currency did not match';
    return undef;
  }

  return $result->{Address};
}

################################################################################
=item B<withdraw($currency, $quantity, $address, $paymentid)>

Used to withdraw funds from your account. note: please account for txfee.

On success, returns the withdrawal UUID as a string.

C<currency> (required) a string literal for the currency (ie. BTC)
C<quantity> (required) the quantity of coins to withdraw
C<address> (required) the address where to send the funds.
C<paymentid> (optional) required for some currencies (memo/tag/etc)

=cut

#---------------------------------------
sub withdraw {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<getorder($uuid)>

Used to retrieve a single order by uuid.

C<uuid> (required) the uuid of the buy or sell order

=cut

#---------------------------------------
sub getorder {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<getorderhistory($market)>

Used to retrieve your order history.

C<market> (optional) a string literal for the market (ie. BTC-LTC). If ommited, will return for all markets

=cut

#---------------------------------------
sub getorderhistory {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<getwithdrawalhistory($currency)>

Used to retrieve your withdrawal history.

C<currency> (optional) a string literal for the currecy (ie. BTC). If omitted, will return for all currencies

=cut

#---------------------------------------
sub getwithdrawalhistory {
  my $self = shift;
  die 'not implemented';  # TODO
}

################################################################################
=item B<getdeposithistory($currency)>

Used to retrieve your deposit history.

C<currency> (optional) a string literal for the currecy (ie. BTC). If omitted, will return for all currencies

=cut

#---------------------------------------
sub getdeposithistory {
  my $self = shift;
  die 'not implemented';  # TODO
}

1;  ## EOM
################################################################################

=back

=head1 COPYRIGHT

Copyright (c) 2017 Jason Heddings

Licensed under the terms of the L<MIT License|https://opensource.org/licenses/MIT>,
which is also included in the original source code of this project.

=cut