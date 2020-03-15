#!/usr/bin/perl

use strict;
use warnings;
use lib ".";
use memmap;

my $old = "old.h";
my $new = "new.h";
my $new2 = "new2.h";

open OLD, "<$old";
open NEW, "<$new";
open NEW2, ">$new2";

my @old_memmaps;
my @new_memmaps;
my $memmap_start = 0;
my $memmap;

while(<OLD>)
{
	chomp $_;

	if ($_ =~ /\bdefined\b/)
	{
		if ($memmap) { push @old_memmaps, $memmap; }

		$memmap_start = 1;
		my @words = grep { $_ ne '' } (split " ", $_);
		my $name = pop @words;
		$memmap = memmap->new();
		$memmap->Name($name);
	}

	elsif ($memmap_start == 1 and $_ =~ /\bdefine\b/)
	{
		my @words = grep { $_ ne '' } (split " ", $_);
		my $subDef = pop @words;
		$memmap->SubDef($subDef);
		$memmap_start = 0;
	}
}

$memmap = "";

while(<NEW>)
{
	chomp $_;

	if ($_ =~ /\bdefined\b/)
	{
		if ($memmap) { push @new_memmaps, $memmap; }

		$memmap_start = 1;
		my @words = grep { $_ ne '' } (split " ", $_);
		my $name = pop @words;
		$memmap = memmap->new();
		$memmap->Name($name);
	}
}

foreach my $memmap (@new_memmaps)
{
	my $name = $memmap->Name;
	my $subDef;

	foreach my $old_memmap (@old_memmaps)
	{
		if ($memmap->Name eq $old_memmap->Name)
		{
			$old_memmap->IsMatch(1);
			$subDef = $old_memmap->SubDef;
		}
	}
	
	if ($subDef)
	{
		print NEW2 <<EOF;
#elif defined $name
    #undef  $name
	#define $subDef
	#include "MemMap.h"

EOF
	}
	else
	{
		print NEW2 <<EOF;
#elif defined $name
    #undef  $name

EOF
	}
}

foreach my $memmap (@old_memmaps)
{
	if ($memmap->SubDef and $memmap->IsMatch == 0)
	{
		my $name = $memmap->Name;
		my $subDef = $memmap->SubDef;

		print <<EOF;
#elif defined $name
    #undef  $name
	#define $subDef
	#include "MemMap.h"

EOF
	}
}

close OLD;
close NEW;
close NEW2;
