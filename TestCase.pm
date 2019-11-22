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
		PostConditions		=> [],
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
sub PostConditions			{ @{$_[0]->{PostConditions	}}; }
sub TestSteps				{ @{$_[0]->{TestSteps		}}; }

sub AddGoal					{ push @{$_[0]->{Goals			    }}, $_[1] if defined $_[1]; }
sub AddDesignItem			{ push @{$_[0]->{DesignItems		}}, $_[1] if defined $_[1]; }
sub AddExpectedResult		{ push @{$_[0]->{ExpectedResults	}}, $_[1] if defined $_[1]; }
sub AddPreCondition			{ push @{$_[0]->{PreConditions		}}, $_[1] if defined $_[1]; }
sub AddPostCondition		{ push @{$_[0]->{PostConditions	    }}, $_[1] if defined $_[1]; }
sub AddTestStep				{ push @{$_[0]->{TestSteps			}}, $_[1] if defined $_[1]; }

sub GoalsCount				{ scalar @{$_[0]->{Goals			}}; }
sub DesignItemsCount		{ scalar @{$_[0]->{DesignItems		}}; }
sub ExpectedResultsCount	{ scalar @{$_[0]->{ExpectedResults	}}; }
sub PreConditionsCount		{ scalar @{$_[0]->{PreConditions	}}; }
sub PostCondtionsCount		{ scalar @{$_[0]->{PostConditions	}}; }
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
	my @postConditions			= $_[0]->PostConditions			;
	my @testSteps				= $_[0]->TestSteps				;
	# my $goalsCount				= $_[0]->GoalsCount				;
	# my $designItemsCount		= $_[0]->DesignItemsCount		;
	# my $expectedResultsCount	= $_[0]->ExpectedResultsCount	;
	# my $preConditionsCount		= $_[0]->PreConditionsCount		;
	# my $postCondtionsCount		= $_[0]->PostCondtionsCount		;
	# my $testStepsCount			= $_[0]->TestStepsCount			;

	my $i = 0;

	print <<EOF;
********************************************************************************
$id Unit Test: $name
$topTag
Test Desciption
EOF

	$i = 0;
    print <<EOF;
Design Items
EOF
	foreach my $designItem (@designItems)
	{
		$i++;
		print <<EOF;
    $i	$designItem
EOF
	}

	$i = 0;
    print <<EOF;
Goals
EOF
	foreach my $goal (@goals)
	{
		$i++;
		print <<EOF;
    $i	$goal
EOF
	}

	$i = 0;
    print <<EOF;
Pre-Condition
EOF
	foreach my $preCondition (@preConditions)
	{
		$i++;
		print <<EOF;
    $i	$preCondition
EOF
	}

	$i = 0;
    print <<EOF;
Test Steps
EOF
	foreach my $testStep (@testSteps)
	{
		$i++;
		print <<EOF;
    $i	$testStep
EOF
	}

    print <<EOF;
Test Case Number    $testNumber
EOF

	$i = 0;
    print <<EOF;
Expected Results
EOF
	foreach my $expectedResult (@expectedResults)
	{
		$i++;
		print <<EOF;
    $i	$expectedResult
EOF
	}

	$i = 0;
    print <<EOF;
Post-Condition
EOF
	foreach my $postCondition (@postConditions)
	{
		$i++;
		print <<EOF;
    $i	$postCondition
EOF
	}

	print <<EOF;
$bottomTag
EOF
}

1;
