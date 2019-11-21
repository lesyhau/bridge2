use strict;

use lib ".";
use TestCase;

my $p = TestCase->new();
$p->Id						(0						);
$p->Name					("test_case_001"		);
$p->TestNumber				("test_case_001"		);
$p->TopTag					("[\$test_case_001]"	);
$p->BottomTag				("[\$test_case_001]"	);
$p->AddGoal					("Goal 1"				);
$p->AddGoal					("Goal 2"				);
$p->AddGoal					("Goal 3"				);
$p->AddDesignItem			("Design Item 1"		);
$p->AddDesignItem			("Design Item 2"		);
$p->AddDesignItem			("Design Item 3"		);
$p->AddExpectedResult		("Result 1"				);
$p->AddExpectedResult		("Result 2"				);
$p->AddExpectedResult		("Result 3"				);
$p->AddPreCondition			("Pre Cond 1"			);
$p->AddPreCondition			("Pre Cond 2"			);
$p->AddPreCondition			("Pre Cond 3"			);
$p->AddPostCondtion			("Post Cond 1"			);
$p->AddPostCondtion			("Post Cond 2"			);
$p->AddPostCondtion			("Post Cond 3"			);
$p->AddTestStep				("Step 1"				);
$p->AddTestStep				("Step 2"				);
$p->AddTestStep				("Step 3"				);

$p->PrintSpecs;