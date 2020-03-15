#!/usr/bin/perl

use strict;
use warnings;

package memmap;

sub new
{
	my $class = shift;

	my $seft = bless
	{
		Id		=> 0,
		Name	=> "",
		SubDef	=> "",
		IsMatch	=> 0
	}, $class;

	return $seft;
}

sub Id		{ $_[0]->{Id		} = $_[1] if defined $_[1]; $_[0]->{Id		}; }
sub Name	{ $_[0]->{Name		} = $_[1] if defined $_[1]; $_[0]->{Name	}; }
sub SubDef	{ $_[0]->{SubDef	} = $_[1] if defined $_[1]; $_[0]->{SubDef	}; }
sub IsMatch	{ $_[0]->{IsMatch	} = $_[1] if defined $_[1]; $_[0]->{IsMatch	}; }

return 1;
