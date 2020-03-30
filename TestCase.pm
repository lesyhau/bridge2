#********************************************************************************
#   UTSG - Unit Test Specification Generator
#   Version 1.0
#   VH3224 - Le Sy Hau
#********************************************************************************

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
		CallSut			    => "",
		Description			=> "",
        ExpectedCalls       => "",
        DesignItem          => "",
		ExpectedResults		=> [],
		PreConditions		=> [],
		PostConditions		=> [],
		TestSteps			=> []
	}, $class;

	return $seft;
}

sub Id						{ $_[0]->{Id			    } = $_[1] if defined $_[1]; $_[0]->{Id			    }; }
sub Name					{ $_[0]->{Name			    } = $_[1] if defined $_[1]; $_[0]->{Name		    }; }
sub TestNumber				{ $_[0]->{TestNumber	    } = $_[1] if defined $_[1]; $_[0]->{TestNumber	    }; }
sub TopTag					{ $_[0]->{TopTag		    } = $_[1] if defined $_[1]; $_[0]->{TopTag		    }; }
sub BottomTag				{ $_[0]->{BottomTag		    } = $_[1] if defined $_[1]; $_[0]->{BottomTag	    }; }
sub CallSut				    { $_[0]->{CallSut	        } = $_[1] if defined $_[1]; $_[0]->{CallSut	        }; }
sub Description				{ $_[0]->{Description		} = $_[1] if defined $_[1]; $_[0]->{Description		}; }
sub ExpectedCalls           { $_[0]->{ExpectedCalls     } = $_[1] if defined $_[1]; $_[0]->{ExpectedCalls   }; }
sub DesignItem              { $_[0]->{DesignItem        } = $_[1] if defined $_[1]; $_[0]->{DesignItem      }; }

sub PreConditions			{ @{$_[0]->{PreConditions	}}; }
sub PostConditions			{ @{$_[0]->{PostConditions	}}; }
sub TestSteps				{ @{$_[0]->{TestSteps		}}; }
sub ExpectedResults			{ @{$_[0]->{ExpectedResults }}; }

sub AddPreCondition			{ push @{$_[0]->{PreConditions		}}, $_[1] if defined $_[1]; }
sub AddPostCondition		{ push @{$_[0]->{PostConditions	    }}, $_[1] if defined $_[1]; }
sub AddTestStep				{ push @{$_[0]->{TestSteps			}}, $_[1] if defined $_[1]; }
sub AddExpectedResult       { push @{$_[0]->{ExpectedResults    }}, $_[1] if defined $_[1]; }

sub PreConditionsCount		{ scalar @{$_[0]->{PreConditions	}}; }
sub PostConditionsCount		{ scalar @{$_[0]->{PostConditions	}}; }
sub TestStepsCount			{ scalar @{$_[0]->{TestSteps		}}; }
sub ExpectedResultsCount    { scalar @{$_[0]->{ExpectedResults  }}; }

sub ClearPreConditions      { @{$_[0]->{PreConditions   }} = (); }
sub ClearPostConditions     { @{$_[0]->{PostConditions	}} = (); }
sub ClearTestSteps          { @{$_[0]->{TestSteps		}} = (); }
sub ClearExpectedResults    { @{$_[0]->{ExpectedResults }} = (); }

1;
