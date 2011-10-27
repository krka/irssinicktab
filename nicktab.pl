use Irssi;
use Irssi::TextUI;
use strict;

use vars qw($VERSION %IRSSI);

$VERSION="0.5.5";
%IRSSI = (
	authors=> 'krka',
	contact=> 'kristofer.karlsson@gmail.com',
	name=> 'nicktab',
	description=> 'Nick completion that works like bash tab',
	license=> 'GPL v2',
	url=> 'N/A',
);

sub completeNick {
	my ($complist, $nick, $pushchar, $done) = @_;
	if (!$done) {
		$pushchar = "";
	}
	push (@{$complist}, $nick . $pushchar);
	Irssi::signal_stop();
}

sub sig_complete {
	my ($complist, $window, $word, $linestart, $want_space) = @_;

	my $channel = $window->{active};

	# the completion is ok if this is a channel
	if ($channel->{type} ne "CHANNEL") {
		return;
	}

	my (@nicks);

	my $quoted = quotemeta $word;

	foreach my $n ($channel->nicks()) {
		my $nick = $n->{nick};
		if ($nick =~ /^$quoted/i && $window->{active_server}->{nick} ne $n->{nick}) {
			push(@nicks,$n->{nick});
		}
	}

	my $pushchar = Irssi::settings_get_str('completion_char');
	if (!($linestart eq "")) {
		$pushchar = "";
	}

	if (scalar @nicks lt 1) {
		return;
	} elsif (scalar @nicks eq 1) {
		completeNick($complist, $nicks[0], $pushchar, 1);
	} else {
		@nicks = sort(@nicks);

		my $prev;
		my $shortestNick;
		foreach my $n (@nicks) {
			if (!$prev) {
				$shortestNick = $n;
			} else {
				my $i = 0;
				while ($i < length($n) && $i < length($prev) && lc(substr($n, $i, 1)) eq lc(substr($prev, $i, 1))) {
					$i++;
				}
				if ($i < length($shortestNick)) {
					$shortestNick = substr($n, 0, $i);
				}
			}
			$prev = $n;
		}
		if ($word == $shortestNick) {
			my $niqString;
			$niqString = "";
			foreach my $n (@nicks) {
				my $x = length($shortestNick);
				my $pre = substr($n, 0, $x);
				my $highlight = substr($n, $x, 1);
				my $post = substr($n, $x + 1);
				my $coloredNick =  "$pre%y$highlight%n$post";
				$niqString .= "$coloredNick ";
			}
			$window->print($niqString);
		}
		$$want_space = 0;
		completeNick($complist, $word . substr($shortestNick, length($word)), $pushchar, 0);
	}
}

Irssi::signal_add_first('complete word', 'sig_complete');

