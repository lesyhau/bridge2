use strict;

package TestCase;

sub new
{
	my $class = shift;

	my $seft = bless
	{
		Id					=> 0,
		Name				=> "",
		TestNumber			=> "",
		TopTag				=> "",
		BottomTag			=> "",
		Goals				=> [],
		DesignItems			=> [],
		ExpectedResults		=> [],
		PreConditions		=> [],
		PostCondtions		=> [],
		TestSteps			=> []
	}, $class;

	return $seft;
}

sub Id						{ $_[0]->{Id			} = $_[1] if defined $_[1]; $_[0]->{Id			}; }
sub Name					{ $_[0]->{Name			} = $_[1] if defined $_[1]; $_[0]->{Name		}; }
sub TestNumber				{ $_[0]->{TestNumber	} = $_[1] if defined $_[1]; $_[0]->{TestNumber	}; }
sub TopTag					{ $_[0]->{TopTag		} = $_[1] if defined $_[1]; $_[0]->{TopTag		}; }
sub BottomTag				{ $_[0]->{BottomTag		} = $_[1] if defined $_[1]; $_[0]->{BottomTag	}; }
sub Goals					{ @{$_[0]->{Goals			}}; }
sub DesignItems				{ @{$_[0]->{DesignItems		}}; }
sub ExpectedResults			{ @{$_[0]->{ExpectedResults	}}; }
sub PreConditions			{ @{$_[0]->{PreConditions	}}; }
sub PostCondtions			{ @{$_[0]->{PostCondtions	}}; }
sub TestSteps				{ @{$_[0]->{TestSteps		}}; }
sub AddGoal					{ @{$_[0]->{Goals			}}; }
sub AddDesignItem			{ push @{$_[0]->{DesignItems		}}, $_[1] if defined $_[1]; }
sub AddExpectedResult		{ push @{$_[0]->{ExpectedResults	}}, $_[1] if defined $_[1]; }
sub AddPreCondition			{ push @{$_[0]->{PreConditions		}}, $_[1] if defined $_[1]; }
sub AddPostCondtion			{ push @{$_[0]->{PostCondtions		}}, $_[1] if defined $_[1]; }
sub AddTestStep				{ push @{$_[0]->{TestSteps			}}, $_[1] if defined $_[1]; }
sub GoalsCount				{ scalar @{$_[0]->{Goals			}}; }
sub DesignItemsCount		{ scalar @{$_[0]->{DesignItems		}}; }
sub ExpectedResultsCount	{ scalar @{$_[0]->{ExpectedResults	}}; }
sub PreConditionsCount		{ scalar @{$_[0]->{PreConditions	}}; }
sub PostCondtionsCount		{ scalar @{$_[0]->{PostCondtions	}}; }
sub TestStepsCount			{ scalar @{$_[0]->{TestSteps		}}; }

sub PrintSpecs
{
	my $id						= $_[0]->Id						;
	my $name					= $_[0]->Name					;
	my $testNumber				= $_[0]->TestNumber				;
	my $topTag					= $_[0]->TopTag					;
	my $bottomTag				= $_[0]->BottomTag				;
	my @goals					= $_[0]->Goals					;
	my @designItems				= $_[0]->DesignItems			;
	my @expectedResults			= $_[0]->ExpectedResults		;
	my @preConditions			= $_[0]->PreConditions			;
	my @postCondtions			= $_[0]->PostCondtions			;
	my @testSteps				= $_[0]->TestSteps				;
	my $goalsCount				= $_[0]->GoalsCount				;
	my $designItemsCount		= $_[0]->DesignItemsCount		;
	my $expectedResultsCount	= $_[0]->ExpectedResultsCount	;
	my $preConditionsCount		= $_[0]->PreConditionsCount		;
	my $postCondtionsCount		= $_[0]->PostCondtionsCount		;
	my $testStepsCount			= $_[0]->TestStepsCount			;

	my $i = 0;

	print <<EOF;
$id Unit Test: $name
$topTag
EOF

	$i = 0;
	foreach my $designItem (@designItems)
	{
		$i++;
		print <<EOF;
Design Item	$i	$designItem
EOF
	}

	$i = 0;
	foreach my $goal (@goals)
	{
		$i++;
		print <<EOF;
Goal	$i	$goal
EOF
	}

	print <<EOF;
$bottomTag
EOF
}

1;