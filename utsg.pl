#********************************************************************************
#   UTSG - Unit Test Specification Generator
#   Version 1.1
#   VH3224 - Le Sy Hau
#********************************************************************************

#********************************************************************************
#   Revison history
#********************************************************************************
#   Rev.    Date        Description
#********************************************************************************
#   1.0     12/12/2019  First release
#********************************************************************************
#   1.1     26/03/2020  Bugs fix:
#                           + UTSG duplicates the previous test case if
#                           the next test case body is commentted.
#                       Improvements:
#                           + UTSG will sorts the test cases list by Id before
#                           generating the UT sepcification.
#********************************************************************************

use strict;
use Getopt::Long;
use Cwd;
use File::Basename;
use File::Spec;
use File::Basename;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Word';
# use Win32::OLE::Const 'Microsoft Office';

use lib File::Spec->catdir(File::Basename::dirname(Cwd::abs_path __FILE__), '.');
use lib File::Spec->catdir(File::Basename::dirname(Cwd::abs_path __FILE__), './scripts');
use TestCase;

my $EXTERNS_START               = "extern";
my $TEST_CASE_START             = "doIt";
my $PRE_CONDITIONS_START        = "Set global data";
my $POST_CONDITIONS_START       = "Set expected values for global data checks";
my $DATA_DECLARATIONS_START     = "Test case data declarations";
my $DESCRIPTION_START           = "START_TEST";
my $EXPECTED_CALLS_START        = "Expected Call Sequence";
my $CALL_SUT_START              = "Call SUT";
my $EXPECTED_RESULTS_START      = "Test case checks";
my $BOTTOM_TAG_START            = "WRITE_LOG";
my $TEST_CASE_END               = "}}";

my $STATE_GET_EXTERNS           = 0;
my $STATE_GET_TEST_CASE_NAME    = 1;
my $STATE_GET_PRE_CONDITIONS    = 2;
my $STATE_GET_POST_CONDITIONS   = 3;
my $STATE_GET_DATA_DECLARATIONS = 4;
my $STATE_GET_DESCRIPTION       = 5;
my $STATE_GET_EXPECTED_CALLS    = 6;
my $STATE_GET_CALL_SUT          = 7;
my $STATE_GET_EXPECTED_RESULTS  = 8;
my $STATE_GET_BOTTOM_TAG        = 9;

my @STATES_TEXT;
push @STATES_TEXT, "GET_EXTERNS";
push @STATES_TEXT, "GET_TEST_CASE_NAME";
push @STATES_TEXT, "GET_PRE_CONDITIONS";
push @STATES_TEXT, "GET_POST_CONDITIONS";
push @STATES_TEXT, "GET_DATA_DECLARATIONS";
push @STATES_TEXT, "GET_DESCRIPTION";
push @STATES_TEXT, "GET_EXPECTED_CALLS";
push @STATES_TEXT, "GET_CALL_SUT";
push @STATES_TEXT, "GET_EXPECTED_RESULTS";
push @STATES_TEXT, "GET_BOTTOM_TAG";

my $curDir = getcwd();
my $outFile = "";
my $utSrc = "";
my $sutSrc = "";
my $outDir = $curDir;
my $debugOn = "";
my $verboseOn = "";
my $msWordVisible = "";
my $noExportDocx = "";
my $help = "";

my $opt = &GetOptions("-ut=s"           => \$utSrc,
                      "-sut=s"          => \$sutSrc,
                      "-out_dir=s"      => \$outDir,
                      "-debug"          => \$debugOn,
                      "-verbose"        => \$verboseOn,
                      "-show_word"      => \$msWordVisible,
                      "-help"           => \$help);

if ($help) { showHelps(); }
if ($debugOn) { $noExportDocx = 1; $verboseOn = 1; }

if ($utSrc)
{
    $utSrc = convertWindowsPath2UnixPath($utSrc);
    if (! isCSource($utSrc)){ die "Error: $utSrc is not a C source file.\n"; }
    if (! -f $utSrc) { die "Error: No such file $utSrc\n"; }
}
else { die "Error: No UT source file specified.\n"; }

if ($sutSrc)
{
    $sutSrc = convertWindowsPath2UnixPath($sutSrc);
    if (! isCSource($utSrc)) { die "Error: $sutSrc is not a C source file.\n"; }
    if (! -f $sutSrc) { die "Error: No such file $sutSrc\n"; }
}

$outDir = convertWindowsPath2UnixPath($outDir);
if (! -d $outDir) { die "Error: No such directory $outDir\n"; }

my $utBasename = basename($utSrc, ".c");
my $outSpecsName = "$utBasename.docx";
my $outLogName = "$utBasename.log";
my $outSpecsPath = "$outDir/$outSpecsName";
my $outLogPath = "$outDir/$outLogName";

my $state = $STATE_GET_EXTERNS;
my @externs;
my $testCase;
my $testCaseId = 0;
my @testCases;
my $curIndex = 0;
my $lineNo = 0;

open LOG, ">$outLogPath" or die "Error: Cannot open file $outLogPath\n";
open UT, "<$utSrc" or die "Error: Cannot open file $utSrc\n";

$lineNo = 0;
while (<UT>)
{
    chomp $_;
    
    # Get extern declarations
    if ($state == $STATE_GET_EXTERNS)
    {
        my $extern = getExtern($_, $lineNo);
        if ($extern) { push @externs, $extern; }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Start of a test case function
    if ($state == $STATE_GET_TEST_CASE_NAME)
    {
        my $testCaseName = getName($_, $lineNo);
        if ($testCaseName)
        {
            $testCase = TestCase->new();
            $testCase->Name($testCaseName);

            my @words = grep { $_ ne "" } (split /_/, extractName($_));
            my $id = pop @words;
            $testCase->Id($id);
        }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get pre condition
    if ($state == $STATE_GET_PRE_CONDITIONS)
    {
        my $preCondition = getPreCondition($_, $lineNo);
        if ($preCondition) { $testCase->AddPreCondition($preCondition); }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get post condition
    if ($state == $STATE_GET_POST_CONDITIONS)
    {
        my $postCondition = getPostCondition($_, $lineNo);
        if ($postCondition) { $testCase->AddPostCondition($postCondition); }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get data declarations
    if ($state == $STATE_GET_DATA_DECLARATIONS)
    {
        # Do nothing

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get description
    if ($state == $STATE_GET_DESCRIPTION)
    {
        my $description = getDescription($_, $lineNo);
        if ($description) { $testCase->Description($description); }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get expected calls
    if ($state == $STATE_GET_EXPECTED_CALLS)
    {
        my $expectedCalls = getExpectedCalls($_, $lineNo);
        if ($expectedCalls) { $testCase->ExpectedCalls($expectedCalls); }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get test steps
    if ($state == $STATE_GET_CALL_SUT)
    {
        my $callSut = getCallSut($_, $lineNo);
        if ($callSut)
        {
            $testCase->CallSut($callSut);
            $testCase->AddTestStep($callSut);
        }

        $state = calculateNextState($state, $_, $lineNo);
    }

    # Get expected results
    if ($state == $STATE_GET_EXPECTED_RESULTS)
    {
        my $expectedResult = getExpectedResult($_, $lineNo);
        if ($expectedResult) { $testCase->AddExpectedResult($expectedResult); }

        $state = calculateNextState($state, $_, $lineNo);
        if ($state eq $STATE_GET_TEST_CASE_NAME) { addTestCase($testCase); }
    }

    # Get tag
    if ($state == $STATE_GET_BOTTOM_TAG)
    {
        my $bottomTag = getBottomTag($_, $lineNo);
        if ($bottomTag)
        {
            $bottomTag = join "", $testCase->BottomTag, $bottomTag;
            $testCase->BottomTag($bottomTag);
        }

        $state = calculateNextState($state, $_, $lineNo);
        if ($state eq $STATE_GET_TEST_CASE_NAME) { addTestCase($testCase); }
    }

    $lineNo++;
}

close UT;

# Sort test cases list by Id
@testCases = sort { $a->{Id} <=> $b->{Id} } @testCases;

if ($noExportDocx) { exit; }

if (-f $outSpecsPath)
{
    (my $outSpecsPath_win = $outSpecsPath) =~ tr!/!\\!;
    system("copy $outSpecsPath_win $outSpecsPath_win.bak");
    system("del $outSpecsPath_win");
    print "Info: Backed up $outSpecsPath as $outSpecsPath.bak\n";
}

print "Info: Generating $outSpecsPath...\n";

my $msWord = CreateObject Win32::OLE 'Word.Application' or die "Error: Cannot open MS Word. $!\n";
$msWord->{Visible} = $msWordVisible;

my $doc = $msWord->Documents->Add;

# $doc->Styles("Heading 1")->Font->{Name} = "Tahoma";
# $doc->Styles("Heading 1")->Font->{Size} = 11;
# $doc->Styles("Heading 1")->Font->{Bold} = 1;
# $doc->Styles("Heading 1")->Font->{ColorIndex} = wdBlack;
# $doc->Styles("Normal")->Font->{Name} = "Tahoma";
# $doc->Styles("Normal")->Font->{Size} = 10;
# $doc->Styles("Normal")->Font->{Bold} = 0;
# $doc->Styles("Normal")->Font->{ColorIndex} = wdBlack;

$doc->Styles->Add("Normal1", wdStyleTypeParagraph);
# $doc->Styles("Normal1")->Font->{Name} = "Tahoma";
# $doc->Styles("Normal1")->Font->{Size} = 10;
$doc->Styles("Normal1")->Font->{Bold} = 1;
# $doc->Styles("Normal1")->Font->{ColorIndex} = wdBlack;

$doc->Styles->Add("Table1", wdStyleTypeTable);
$doc->Styles("Table1")->Table->Borders->{Enable} = 1;
$doc->Styles("Table1")->Table->Condition(wdFirstRow)->Shading->{BackgroundPatternColor} = wdColorGray10;
$doc->Styles("Table1")->Table->Condition(wdFirstColumn)->Shading->{BackgroundPatternColor} = wdColorGray10;
$doc->Styles("Table1")->Table->Condition(wdFirstRow)->Borders->{Enable} = 1;
$doc->Styles("Table1")->Table->Condition(wdFirstColumn)->Borders->{Enable} = 1;

my $progressTotal = scalar @testCases;
my $progress = 0;

foreach my $testCase (@testCases)
{
    $progress++;

    my $id              = $testCase->Id                 ;
    my $name            = $testCase->Name				;
    my $testNumber      = $testCase->TestNumber			;
    my $topTag          = $testCase->TopTag				;
    my $bottomTag       = $testCase->BottomTag			;
    my $callSut         = $testCase->CallSut            ;
    my $description     = $testCase->Description        ;
    my $expectedCalls   = $testCase->ExpectedCalls      ;
    my $designItem      = $testCase->DesignItem         ;
    my @expectedResults = $testCase->ExpectedResults    ;
    my @preConditions   = $testCase->PreConditions		;
    my @postConditions  = $testCase->PostConditions		;
    my @testSteps       = $testCase->TestSteps			;

    if (scalar @preConditions == 0) { push @preConditions, "None"; }
    if (scalar @postConditions == 0) { push @postConditions, "None"; }
    if (scalar @expectedResults == 0) { push @expectedResults, "None"; }

    my $expectedResultsCount = scalar @expectedResults;
    my $preConditionsCount   = scalar @preConditions;
    my $postConditionsCount  = scalar @postConditions;
    my $testStepsCount       = scalar @testSteps;

    my $testDescriptionRow = 1;
    my $designItemRow = $testDescriptionRow + 1;
    my $descriptionRow = $designItemRow + 1;
    my $preConditionsRow = $descriptionRow + 1;
    my $testStepsRow = $preConditionsRow + $preConditionsCount;
    my $testCaseNumberRow = $testStepsRow + $testStepsCount;
    my $expectedResultsRow = $testCaseNumberRow + 1;
    my $postConditionsRow = $expectedResultsRow + $expectedResultsCount;
    my $tableRowsCount = $postConditionsRow + $postConditionsCount - 1;
    my $tableColsCount = 3;

    print "Progress: $progress/$progressTotal", "\n";
    
    if ($verboseOn)
    {
        print "\n********************************************************************************\n";
        print "Progress: $progress/$progressTotal", "\n";
        print "Name: ", $name, "\n";
        print "TopTag: ", $topTag, "\n";
        print "DesignItem: ", $designItem, "\n";
        print "Description: ", $description, "\n";
        foreach my $preCondition (@preConditions) { print "PreCondition: ", transformPreCondition($preCondition), "\n"; }
        foreach my $testStep (@testSteps) { print "TestStep: ", transformTestStep($testStep), "\n"; }
        print "TestNumber: ", $testNumber, "\n";
        foreach my $postCondition (@postConditions) { print "PostCondition: ", transformPostCondition($postCondition), "\n"; }
        foreach my $expectedResult (@expectedResults) { print "ExpectedResult: ", transformExpectedResult($expectedResult, $callSut), "\n"; }
        print "BottomTag: ", $bottomTag, "\n";
    }

    print LOG "\n********************************************************************************\n";
    print LOG "Progress: $progress/$progressTotal", "\n";
    print LOG "Name: ", $name, "\n";
    print LOG "TopTag: ", $topTag, "\n";
    print LOG "DesignItem: ", $designItem, "\n";
    print LOG "Description: ", $description, "\n";
    foreach my $preCondition (@preConditions) { print LOG "PreCondition: ", transformPreCondition($preCondition), "\n"; }
    foreach my $testStep (@testSteps) { print LOG "TestStep: ", transformTestStep($testStep), "\n"; }
    print LOG "TestNumber: ", $testNumber, "\n";
    foreach my $postCondition (@postConditions) { print LOG "PostCondition: ", transformPostCondition($postCondition), "\n"; }
    foreach my $expectedResult (@expectedResults) { print LOG "ExpectedResult: ", transformExpectedResult($expectedResult, $callSut), "\n"; }
    print LOG "BottomTag: ", $bottomTag, "\n";

    # Make sure that the cursor is currently at a new page
    if ($id != 0) { $msWord->Selection->InsertBreak(wdPageBreak); }

    # Test case name
    $msWord->Selection->{Style} = "Heading 2";
    $msWord->Selection->TypeText("Unit Test: $name");
    $msWord->Selection->TypeParagraph;
    $msWord->Selection->{Style} = "Normal";

    # Make sure that the cursor is currently at the bottom of the document
    $msWord->Selection->EndKey(wdStory);

    # Top tag
    $msWord->Selection->{Style} = "Normal1";
    $msWord->Selection->TypeText($topTag);
    $msWord->Selection->TypeParagraph;
    $msWord->Selection->{Style} = "Normal";

    # Make sure that the cursor is currently at the bottom of the document
    $msWord->Selection->EndKey(wdStory);

    # Create the description table
    my $table = $doc->Tables->Add($msWord->Selection->Range, $tableRowsCount, $tableColsCount, wdWord8TableBehavior, wdAutoFitFixed);
    $table->Columns(1)->SetWidth($msWord->CentimetersToPoints(3.5), wdAdjustNone);
    $table->Columns(2)->SetWidth($msWord->CentimetersToPoints(1), wdAdjustNone);
    $table->Columns(3)->SetWidth($msWord->CentimetersToPoints(12), wdAdjustNone);
    $msWord->Selection->{Style} = "Table1";

    # Test Description
    $table->Cell($testDescriptionRow, 1)->Range->{Text} = "Test Description";
    $msWord->Selection->MoveDown(wdLine, 1);

    # Design Item
    $table->Cell($designItemRow, 1)->Range->{Text} = "Design Item";
    $table->Cell($designItemRow, 2)->Range->{Text} = $designItem;
    $msWord->Selection->MoveDown(wdLine, 1);

    # Description
    $table->Cell($descriptionRow, 1)->Range->{Text} = "Goal";
    $table->Cell($descriptionRow, 2)->Range->{Text} = "Test function in normal case for getting the coverage of function";
    $msWord->Selection->MoveDown(wdLine, 1);

    # Pre-conditions
    $table->Cell($preConditionsRow, 1)->Range->{Text} = "Pre-Conditions";
    for (my $i = 0; $i < $preConditionsCount; $i++)
    {
        if ($preConditions[$i] ne "None") { $table->Cell($preConditionsRow + $i, 2)->Range->{Text} = $i + 1; }
        $table->Cell($preConditionsRow + $i, 3)->Range->{Text} = transformPreCondition($preConditions[$i]);
        $msWord->Selection->MoveDown(wdLine, 1);
    }

    # Test steps
    $table->Cell($testStepsRow, 1)->Range->{Text} = "Test Steps";
    for (my $i = 0; $i < $testStepsCount; $i++)
    {
        if ($testSteps[$i] ne "None") { $table->Cell($testStepsRow + $i, 2)->Range->{Text} = $i + 1; }
        $table->Cell($testStepsRow + $i, 3)->Range->{Text} = transformTestStep($testSteps[$i]);
        $msWord->Selection->MoveDown(wdLine, 1);
    }

    # Test Case Number
    $table->Cell($testCaseNumberRow, 1)->Range->{Text} = "Test Case Number";
    $table->Cell($testCaseNumberRow, 2)->Range->{Text} = $testNumber;
    $msWord->Selection->MoveDown(wdLine, 1);

    # Expected Results
    $table->Cell($expectedResultsRow, 1)->Range->{Text} = "Expected Results";
    for (my $i = 0; $i < $expectedResultsCount; $i++)
    {
        if ($expectedResults[$i] ne "None") { $table->Cell($expectedResultsRow + $i, 2)->Range->{Text} = $i + 1; }
        $table->Cell($expectedResultsRow + $i, 3)->Range->{Text} = transformExpectedResult($expectedResults[$i], $callSut);
        $msWord->Selection->MoveDown(wdLine, 1);
    }
    $msWord->Selection->MoveDown(wdLine, 1);

    # Post-condition
    $table->Cell($postConditionsRow, 1)->Range->{Text} = "Post-Conditions";
    for (my $i = 0; $i < $postConditionsCount; $i++)
    {
        if ($postConditions[$i] ne "None") { $table->Cell($postConditionsRow + $i, 2)->Range->{Text} = $i + 1; }
        $table->Cell($postConditionsRow + $i, 3)->Range->{Text} = transformPostCondition($postConditions[$i]);
        $msWord->Selection->MoveDown(wdLine, 1);
    }

    $msWord->Selection->MoveDown(wdLine, 1);

    # Merge cells
    $table->Cell($testDescriptionRow, 1)->Merge($table->Cell($testDescriptionRow, 2));
    $table->Cell($testDescriptionRow, 1)->Merge($table->Cell($testDescriptionRow, 2));
    $table->Cell($designItemRow, 2)->Merge($table->Cell($designItemRow, 3));
    $table->Cell($descriptionRow, 2)->Merge($table->Cell($descriptionRow, 3));
    $table->Cell($testCaseNumberRow, 2)->Merge($table->Cell($testCaseNumberRow, 3));
    if ($preConditionsCount > 1)
    {
        for (my $i = 0; $i < $preConditionsCount - 1; $i++)
        {
            $table->Cell($preConditionsRow, 1)->Merge($table->Cell($preConditionsRow + $i + 1, 1));
        }
    }
    if ($postConditionsCount > 1)
    {
        for (my $i = 0; $i < $postConditionsCount - 1; $i++)
        {
            $table->Cell($postConditionsRow, 1)->Merge($table->Cell($postConditionsRow + $i + 1, 1));
        }
    }
    if ($testStepsCount > 1)
    {
        for (my $i = 0; $i < $testStepsCount - 1; $i++)
        {
            $table->Cell($testStepsRow, 1)->Merge($table->Cell($testStepsRow + $i + 1, 1));
        }
    }
    
    # Make sure that the cursor is currently at the bottom of the document
    $msWord->Selection->EndKey(wdStory);

    # Bottom tag
    $msWord->Selection->{Style} = "Normal1";
    $msWord->Selection->TypeText($bottomTag);
    $msWord->Selection->TypeParagraph;
    $msWord->Selection->{Style} = "Normal";
}

$doc->Range->ParagraphFormat->{SpaceBefore} = 6;
$doc->Range->ParagraphFormat->{SpaceAfter} = 0;
$doc->Range->ParagraphFormat->{LineSpacingRule} = wdLineSpace1pt5;

$doc->SaveAs($outSpecsPath);
$doc->Close();
$msWord->Quit();

close LOG;

print "Info: $outSpecsPath has been generated successfully.\n";




my $streamMultipleLinesStart = 0;
my $streamMultipleLinesEnd = 0;
my $streamMultipleLinesStream = "";
sub streamMultipleLines
{
    my $line = shift;
    my $lineNo = shift;
    my $content = "";
    
    if ($streamMultipleLinesStart == 0) { $streamMultipleLinesStart = 1; }

    if ($streamMultipleLinesStart == 1 and $streamMultipleLinesEnd == 0)
    {
        my @words = grep { $_ ne "" } (split /[ ]/, $line);
        if ($words[0] !~ /\//) { $streamMultipleLinesStream = join " ", $streamMultipleLinesStream, @words; }
    }

    if (($line =~ /;$/) and ($streamMultipleLinesStart == 1)) { $streamMultipleLinesEnd = 1; }

    if ($streamMultipleLinesEnd == 1)
    {
        $content = $streamMultipleLinesStream;

        $streamMultipleLinesStart = 0;
        $streamMultipleLinesEnd = 0;
        $streamMultipleLinesStream = "";
    }

    return $content;
}

sub getExtern
{
    my $line = shift;
    my $lineNo = shift;
    my $extern = "";

    my $stream = streamMultipleLines($line, $lineNo);
    if ($stream =~ /extern/)
    {
        $extern = extractExtern($stream);
        if ($verboseOn) { print "getExtern: \$extern: ", $extern, "\n"; }
        print LOG "getExtern: \$extern: ", $extern, "\n";
    }

    return $extern;
}

sub extractExtern
{
    my $line = shift;

    my @words = grep { $_ ne "" } (split /[ ;]/, $line);
    my $length = scalar @words;
    my $e = 0;

    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] eq "extern")
        {
            $e = $i;
            $i = $length;
        }
    }

    my $extern = join " ", @words[$e+1..$length];

    return $extern;
}

sub getName
{
    my $line = shift;
    my $lineNo = shift;
    my $testCaseName = "";

    if ($line =~ /^void/ and $line =~ /int/ and $line =~ /doIt/)
    {
        $testCaseName = $line;
        if ($verboseOn) { print "\n\n\n"; }
        if ($verboseOn) { print "--------------------------------------------------------------------------------\n"; }
        if ($verboseOn) { print "getName: \$testCaseName: ", $testCaseName, "\n"; }
        print LOG "\n\n\n";
        print LOG "--------------------------------------------------------------------------------\n";
        print LOG "getName: \$testCaseName: ", $testCaseName, "\n";
    }

    return $testCaseName;
}

sub extractName
{
    my $line = shift;

    my @words = grep { $_ ne "" } (split /[ ()]/, $line);
    my $testCaseName = $words[1];
    if ($verboseOn) { print "extractName: \$testCaseName: ", $testCaseName, "\n"; }
    print LOG "extractName: \$testCaseName: ", $testCaseName, "\n";

    return $testCaseName;
}

sub extractTopTag
{
    my $testCaseName = shift;
    my $topTag = join "", "[", "\$", $testCaseName, "]";
    if ($verboseOn) { print "extractTopTag: \$topTag: ", $topTag, "\n"; }
    print LOG "extractTopTag: \$topTag: ", $topTag, "\n";
    return $topTag;
}

sub extractTestNumber
{
    my $testCaseName = shift;
    my $testCaseNumber = $testCaseName;
    if ($verboseOn) { print "extractTestNumber: \$testCaseNumber: ", $testCaseNumber, "\n"; }
    print LOG "extractTestNumber: \$testCaseNumber: ", $testCaseNumber, "\n";
    return $testCaseName;
}

sub getPreCondition
{
    my $line = shift;
    my $lineNo = shift;
    my $preCondition = "";

    if ($line =~ /=/ and $line =~ /;$/ and $line !~ /^\//)
    {
        $preCondition = $line;
        if ($verboseOn) { print "getPreCondition: \$preCondition: ", $preCondition, "\n"; }
        print LOG "getPreCondition: \$preCondition: ", $preCondition, "\n";
    }

    return $preCondition;
}

sub extractPreCondition
{
    my $line = shift;
    my $preCondition = "";

    my @words = grep { $_ ne "" } (split /[=;]/, $line);
    my $var = removeSpaces($words[0]);
    my $val = removeSpaces($words[1]);

    if ($var =~ /ACCESS_VARIABLE\(/) { $var = extract_ACCESS_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_VARIABLE($var); }
    elsif ($var =~ /ACCESS_EXPECTED_VARIABLE\(/) { $var = extract_ACCESS_EXPECTED_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_SCOPE_VARIABLE($var); }
    elsif ($var =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $var = extract_LOCAL_VARIABLE_ACCESSOR($var); }

    if ($val =~ /ACCESS_VARIABLE\(/) { $val = extract_ACCESS_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_VARIABLE($val); }
    elsif ($val =~ /ACCESS_EXPECTED_VARIABLE\(/) { $val = extract_ACCESS_EXPECTED_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_SCOPE_VARIABLE($val); }
    elsif ($val =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $val = extract_LOCAL_VARIABLE_ACCESSOR($val); }

    $preCondition = "$var,=,$val";
    if ($verboseOn) { print "extractPreCondition: \$preCondition: ", $preCondition, "\n"; }
    print LOG "extractPreCondition: \$preCondition: ", $preCondition, "\n";

    return $preCondition;
}

sub getPostCondition
{
    my $line = shift;
    my $lineNo = shift;
    my $postCondition = "";

    if ($line =~ /=/ and $line =~ /;$/ and $line !~ /^\//)
    {
        $postCondition = $line;
        if ($verboseOn) { print "getPostCondition: \$postCondition: ", $postCondition, "\n"; }
        print LOG "getPostCondition: \$postCondition: ", $postCondition, "\n";
    }

    return $postCondition;
}

sub extractPostCondition
{
    my $line = shift;
    my $postCondition = "";

    $line = removeSpaces($line);
    my @words = grep { $_ ne "" } (split /[=;]/, $line);
    my $var = removeSpaces($words[0]);
    my $val = removeSpaces($words[1]);

    if ($var =~ /ACCESS_VARIABLE\(/) { $var = extract_ACCESS_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_VARIABLE($var); }
    elsif ($var =~ /ACCESS_EXPECTED_VARIABLE\(/) { $var = extract_ACCESS_EXPECTED_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_SCOPE_VARIABLE($var); }
    elsif ($var =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $var = extract_LOCAL_VARIABLE_ACCESSOR($var); }

    if ($val =~ /ACCESS_VARIABLE\(/) { $val = extract_ACCESS_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_VARIABLE($val); }
    elsif ($val =~ /ACCESS_EXPECTED_VARIABLE\(/) { $val = extract_ACCESS_EXPECTED_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_SCOPE_VARIABLE($val); }
    elsif ($val =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $val = extract_LOCAL_VARIABLE_ACCESSOR($val); }

    $postCondition = "$var,=,$val";
    if ($verboseOn) { print "extractPostCondition: \$postCondition: ", $postCondition, "\n"; }
    print LOG "extractPostCondition: \$postCondition: ", $postCondition, "\n";

    return $postCondition;
}

sub getDescription
{
    my $line = shift;
    my $lineNo = shift;
    my $description = "";

    my $stream = streamMultipleLines($line, $lineNo);
    if ($stream =~ /START_TEST/)
    {
        $description = $stream;
        if ($verboseOn) { print "getDescription: \$description: ", $description, "\n"; }
        print LOG "getDescription: \$description: ", $description, "\n";
    }

    return $description;
}

sub extractDescription
{
    my $line = shift;
    my $description = "";

    my @words = grep { $_ ne "" } (split /[(),;]/, $line);
    $description = pop @words;
    if ($verboseOn) { print "extractDescription: \$description: ", $description, "\n"; }
    print LOG "extractDescription: \$description: ", $description, "\n";

    return $description;
}

sub getExpectedCalls
{
    my $line = shift;
    my $lineNo = shift;
    my $expectedCalls = "";

    my $stream = streamMultipleLines($line, $lineNo);
    if ($stream =~ /EXPECTED_CALLS/)
    {
        $expectedCalls = $stream;
        if ($verboseOn) { print "getExpectedCalls: \$expectedCalls: ", $expectedCalls, "\n"; }
        print LOG "getExpectedCalls: \$expectedCalls: ", $expectedCalls, "\n";
    }

    return $expectedCalls;
}

sub extractExpectedCalls
{
    my $line = shift;
    my @expectedCalls;

    my @words = grep { $_ ne "" } (split /[()"" ;]/, $line);
    my $length = scalar @words;
    if ($length > 1)
    {
        for (my $i = 1; $i < $length; $i++)
        {
            my $expectedCall = $words[$i];
            if ($verboseOn) { print "extractExpectedCalls: \$expectedCall: ", $expectedCall, "\n"; }
            print LOG "extractExpectedCalls: \$expectedCall: ", $expectedCall, "\n";

            push @expectedCalls, $expectedCall;
        }
    }

    return @expectedCalls;
}

sub convertExpectedCall2PreCondition
{
    my $line = shift;
    my $var = "";
    my $val = "void";
    my $preCondition = "";

    my @words = grep { $_ ne "" } (split /[{}#]/, $line);
    $var = $words[0];
    if (scalar @words > 1) { $val = pop @words; }

    $preCondition = "$var,#,$val";
    if ($verboseOn) { print "convertExpectedCall2PreCondition: \$preCondition: ", $preCondition, "\n"; }
    print LOG "convertExpectedCall2PreCondition: \$preCondition: ", $preCondition, "\n";

    return $preCondition;
}

sub getCallSut
{
    my $line = shift;
    my $lineNo = shift;
    my $callSut = "";

    my $stream = streamMultipleLines($line, $lineNo);
    if ($stream)
    {
        $callSut = $stream;
        if ($verboseOn) { print "getCallSut: \$callSut: ", $callSut, "\n"; }
        print LOG "getCallSut: \$callSut: ", $callSut, "\n";
    }

    return $callSut;
}

sub extractCallSut
{
    my $line = shift;
    my $fxnCall = "";
    my $retVar = "void";
    my $callSut = "";

    my @words = grep { $_ ne "" } (split /[=;]/, $line);
    if (scalar @words > 1)
    {
        $fxnCall = removeSpaces(pop @words);
        $retVar = removeSpaces($words[0]);
    }
    else { $fxnCall = removeSpaces($words[0]); }

    if ($fxnCall =~ /ACCESS_FUNCTION\(/) { $fxnCall = extract_ACCESS_FUNCTION($fxnCall); }
    elsif ($fxnCall =~ /ACCESS_SCOPE_FUNCTION\(/) { $fxnCall = extract_ACCESS_SCOPE_FUNCTION($fxnCall); }
    else
    {
        @words = grep { $_ ne "" } (split /[(),]/, $fxnCall);
        $fxnCall = $words[0];
    }

    if ($retVar =~ /ACCESS_VARIABLE\(/) { $retVar = extract_ACCESS_VARIABLE($retVar); }
    elsif ($retVar =~ /ACCESS_LOCAL_VARIABLE\(/) { $retVar = extract_ACCESS_LOCAL_VARIABLE($retVar); }
    elsif ($retVar =~ /ACCESS_EXPECTED_VARIABLE\(/) { $retVar = extract_ACCESS_EXPECTED_VARIABLE($retVar); }
    elsif ($retVar =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $retVar = extract_ACCESS_LOCAL_SCOPE_VARIABLE($retVar); }
    elsif ($retVar =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $retVar = extract_LOCAL_VARIABLE_ACCESSOR($retVar); }

    $callSut = "$retVar,=,$fxnCall";
    if ($verboseOn) { print "extractCallSut: \$callSut: ", $callSut, "\n"; }
    print LOG "extractCallSut: \$callSut: ", $callSut, "\n";

    return $callSut;
}

sub convertCallSut2DesignItem
{
    my $line = shift;
    my $designItem = "";

    my @words = grep { $_ ne "" } (split /[,]/, $line);
    my $fxnCall = $words[2];
    if ($verboseOn) { print "convertCallSut2DesignItem: \$fxnCall: ", $fxnCall, "\n"; }
    print LOG "convertCallSut2DesignItem: \$fxnCall: ", $fxnCall, "\n";

    for (my $i = 0; $i < scalar @externs; $i++)
    {
        if ($externs[$i] =~ /$fxnCall/)
        {
            $designItem = $externs[$i];
            if ($verboseOn) { print "convertCallSut2DesignItem: \$designItem: ", $designItem, "\n"; }
            print LOG "convertCallSut2DesignItem: \$designItem: ", $designItem, "\n";

            $i = scalar @externs;
        }
    }

    if (! $designItem)
    {
        if (! $sutSrc)
        {
            print LOG "Error: Function $fxnCall is used in SUT call, but not declared in $utSrc. SUT source file must be specified using -sut option.\n";
            die "Error: Function $fxnCall is used in SUT call, but not declared in $utSrc. SUT source file must be specified using -sut option.\n";
        }
        else
        {
            open SUT, "<$sutSrc" or die "Error: Cannot open $sutSrc\n";
            my $streamStart = 0;
            my $streamEnd = 0;
            my $stream = "";

            while (<SUT>)
            {
                chomp $_;

                if ($_ =~ /$fxnCall/ and $_ !~ /;$/) { $streamStart = 1; }

                if ($streamStart == 1 and $streamEnd == 0)
                {
                    my @words = grep { $_ ne "" } (split /[ ]/, $line);
                    if ($words[0] !~ /\//) { $stream = join " ", $stream, @words; }
                }

                if ($streamStart == 1 and $stream =~ /{$/) { $streamEnd = 1; }

                if ($streamEnd == 1)
                {
                    $designItem = $stream;
                    if ($verboseOn) { print "convertCallSut2DesignItem: \$designItem: ", $designItem, "\n"; }
                    print LOG "convertCallSut2DesignItem: \$designItem: ", $designItem, "\n";
                }
            }

            close SUT;
        }
    }

    return $designItem;
}

sub convertCallSut2TestStep
{
    my $line = shift;

    my @words = grep { $_ ne "" } (split /[,]/, $line);
    my $testStep = $words[2];
    if ($verboseOn) { print "convertCallSut2TestStep: \$testStep: ", $testStep, "\n"; }
    print LOG "convertCallSut2TestStep: \$testStep: ", $testStep, "\n";

    return $testStep;
}

sub getExpectedResult
{
    my $line = shift;
    my $lineNo = shift;
    my $expectedResult = "";

    if ($line !~ /^\// and $line =~ /CHECK/ and $line =~ /;$/)
    {
        $expectedResult = $line;
        if ($verboseOn) { print "getExpectedResult: \$expectedResult: ", $expectedResult, "\n"; }
        print LOG "getExpectedResult: \$expectedResult: ", $expectedResult, "\n";
    }

    return $expectedResult;
}

sub extractExpectedResult
{
    my $line = shift;
    my $expectedResult = "";

    my @words = grep { $_ ne "" } (split /[,;]/, $line);

    for (my $i = 0; $i < scalar @words; $i++)
    {
        if ($words[$i] =~ /ACCESS_VARIABLE/)
        {
            $words[$i] = join ",", @words[$i..$i+1];
            $words[$i+1] = "";
        }

        elsif ($words[$i] =~ /ACCESS_LOCAL_VARIABLE/)
        {
            $words[$i] = join ",", @words[$i..$i+2];
            $words[$i+1] = "";
            $words[$i+2] = "";
        }

        elsif ($words[$i] =~ /ACCESS_EXPECTED_VARIABLE/)
        {
            $words[$i] = join ",", @words[$i..$i+1];
            $words[$i+1] = "";
        }

        elsif ($words[$i] =~ /ACCESS_LOCAL_SCOPE_VARIABLE/)
        {
            $words[$i] = join ",", @words[$i..$i+3];
            $words[$i+1] = "";
            $words[$i+2] = "";
            $words[$i+3] = "";
        }

        elsif ($words[$i] =~ /LOCAL_VARIABLE_ACCESSOR/)
        {
            $words[$i] = join ",", @words[$i..$i+2];
            $words[$i+1] = "";
            $words[$i+2] = "";
        }
    }

    @words = grep { $_ ne "" } @words;

    my $var = removeSpaces($words[0]);
    my $val = removeSpaces($words[1]);

    if ($var =~ /ACCESS_VARIABLE\(/) { $var = extract_ACCESS_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_VARIABLE($var); }
    elsif ($var =~ /ACCESS_EXPECTED_VARIABLE\(/) { $var = extract_ACCESS_EXPECTED_VARIABLE($var); }
    elsif ($var =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $var = extract_ACCESS_LOCAL_SCOPE_VARIABLE($var); }
    elsif ($var =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $var = extract_LOCAL_VARIABLE_ACCESSOR($var); }
    else
    {
        @words = grep { $_ ne "" } (split /[();]/, $var);
        $var = pop @words;
    }

    if ($val =~ /ACCESS_VARIABLE\(/) { $val = extract_ACCESS_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_VARIABLE($val); }
    elsif ($val =~ /ACCESS_EXPECTED_VARIABLE\(/) { $val = extract_ACCESS_EXPECTED_VARIABLE($val); }
    elsif ($val =~ /ACCESS_LOCAL_SCOPE_VARIABLE\(/) { $val = extract_ACCESS_LOCAL_SCOPE_VARIABLE($val); }
    elsif ($val =~ /LOCAL_VARIABLE_ACCESSOR\(/) { $val = extract_LOCAL_VARIABLE_ACCESSOR($val); }
    else
    {
        @words = grep { $_ ne "" } (split /[();]/, $val);
        $val = pop @words;
    }

    $expectedResult = "$var,=,$val";
    if ($verboseOn) { print "extractExpectedResult: \$expectedResult: ", $expectedResult, "\n"; }
    print LOG "extractExpectedResult: \$expectedResult: ", $expectedResult, "\n";

    return $expectedResult;
}

sub getBottomTag
{
    my $line = shift;
    my $lineNo = shift;
    my $bottomTag = "";

    if ($line =~ /WRITE_LOG/)
    {
        $bottomTag = $line;
        if ($verboseOn) { print "getBottomTag: \$bottomTag: ", $bottomTag, "\n"; }
        print LOG "getBottomTag: \$bottomTag: ", $bottomTag, "\n";
    }

    return $bottomTag;
}

sub extractBottomTag
{
    my $line = shift;
    my $bottomTag = "";

    # Note: Tags must has dollar sign ($)
    my @words = grep { $_ ne "" and $_ =~ /\$/ } (split /[()"",;]/, $line);
    my $bottomTag = join "", @words;

    # Validates --> Tests
    @words = split /Validates/, $bottomTag;
    $bottomTag = join "Tests", @words;

    if ($verboseOn) { print "extractBottomTag: \$bottomTag: ", $bottomTag, "\n"; }
    print LOG "extractBottomTag: \$bottomTag: ", $bottomTag, "\n";

    return $bottomTag;
}

sub removeSpaces
{
    my $org = shift;
    my @words = grep { $_ ne "" } (split /[ ]/, $org);
    my $new = join "", @words;
    return $new;
}

sub isCommentLine
{
    my $line = shift;
    my $lineNo = shift;
    my $isCommentLine = 0;

    my @words = grep { $_ ne "" } (split /[ ]/, $line);
    if ($words[0] =~ /\//) { $isCommentLine = 1; }

    return $isCommentLine;
}

sub calculateNextState
{
    my $curState = shift;
    my $line = shift;
    my $lineNo = shift;
    my $nextState = $curState;

    if      ($_ =~ /^$EXTERNS_START/ and (! isCommentLine($line, $lineNo))) { $nextState = $STATE_GET_EXTERNS; }
    elsif   ($_ =~ /$TEST_CASE_START/ and (! isCommentLine($line, $lineNo))) { $nextState = $STATE_GET_TEST_CASE_NAME; }
    elsif   ($_ =~ /$PRE_CONDITIONS_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_PRE_CONDITIONS; }
    elsif   ($_ =~ /$POST_CONDITIONS_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_POST_CONDITIONS; }
    elsif   ($_ =~ /$DATA_DECLARATIONS_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_DATA_DECLARATIONS; }
    elsif   ($_ =~ /$DESCRIPTION_START/ and $curState != $STATE_GET_EXTERNS and (! isCommentLine($line, $lineNo))) { $nextState = $STATE_GET_DESCRIPTION; }
    elsif   ($_ =~ /$EXPECTED_CALLS_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_EXPECTED_CALLS; }
    elsif   ($_ =~ /$CALL_SUT_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_CALL_SUT; }
    elsif   ($_ =~ /$EXPECTED_RESULTS_START/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_EXPECTED_RESULTS; }
    elsif   ($_ =~ /$BOTTOM_TAG_START/ and $curState != $STATE_GET_EXTERNS and (! isCommentLine($line, $lineNo))) { $nextState = $STATE_GET_BOTTOM_TAG; }
    elsif   ($_ =~ /$TEST_CASE_END/ and $curState != $STATE_GET_EXTERNS) { $nextState = $STATE_GET_TEST_CASE_NAME; }

    if ($verboseOn and ($nextState != $curState))
    {
        print "calculateNextState: State changed at line $lineNo: $STATES_TEXT[$curState] --> $STATES_TEXT[$nextState]", "\n";
        print LOG "calculateNextState: State changed at line $lineNo: $STATES_TEXT[$curState] --> $STATES_TEXT[$nextState]", "\n";
    }

    return $nextState;
}

sub extract_ACCESS_FUNCTION
{
    my $line = shift;
    my $fxnName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    
    for (my $i = 0; $i < scalar @words; $i++)
    {
        if ($words[$i] =~ "ACCESS_FUNCTION") { $fxnName = $words[$i+2]; }
    }

    return $fxnName;
}

sub extract_ACCESS_SCOPE_FUNCTION
{
    my $line = shift;
    my $fxnName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    
    for (my $i = 0; $i < scalar @words; $i++)
    {
        if ($words[$i] =~ "ACCESS_SCOPE_FUNCTION") { $fxnName = $words[$i+3]; }
    }

    return $fxnName;
}

sub extract_ACCESS_VARIABLE
{
    my $line = shift;
    my $varName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    my $length = scalar @words;
    my $s = 0;
    
    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] =~ "ACCESS_VARIABLE") { $s = $i + 2; }
        if ($words[$i] eq "&") { $varName = "&"; }
    }
    $varName = join "", $varName, @words[$s..$length];

    return $varName;
}

sub extract_ACCESS_LOCAL_VARIABLE
{
    my $line = shift;
    my $varName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    my $length = scalar @words;
    my $s = 0;
    
    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] =~ "ACCESS_LOCAL_VARIABLE") { $s = $i + 3; }
        if ($words[$i] eq "&") { $varName = "&"; }
    }
    $varName = join "", $varName, @words[$s..$length];

    return $varName;
}

sub extract_ACCESS_EXPECTED_VARIABLE
{
    my $line = shift;
    my $varName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    my $length = scalar @words;
    my $s = 0;
    
    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] =~ "ACCESS_EXPECTED_VARIABLE") { $s = $i + 2; }
        if ($words[$i] eq "&") { $varName = "&"; }
    }
    $varName = join "", $varName, @words[$s..$length];

    return $varName;
}

sub extract_ACCESS_LOCAL_SCOPE_VARIABLE
{
    my $line = shift;
    my $varName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    my $length = scalar @words;
    my $s = 0;
    
    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] =~ "ACCESS_LOCAL_SCOPE_VARIABLE") { $s = $i + 4; }
        if ($words[$i] eq "&") { $varName = "&"; }
    }
    $varName = join "", $varName, @words[$s..$length];

    return $varName;
}

sub extract_LOCAL_VARIABLE_ACCESSOR
{
    my $line = shift;
    my $varName = "";
    my @words = grep { $_ ne "" } (split /[(), ]/, $line);
    my $length = scalar @words;
    my $s = 0;
    
    for (my $i = 0; $i < $length; $i++)
    {
        if ($words[$i] =~ "LOCAL_VARIABLE_ACCESSOR") { $s = $i + 3; }
        if ($words[$i] eq "&") { $varName = "&"; }
    }
    $varName = join "", $varName, @words[$s..$length];

    return $varName;
}

sub addTestCase
{
    if ($verboseOn) { print "--------------------------------------------------------------------------------\n"; }
    print LOG "--------------------------------------------------------------------------------\n";
    
    my $testCase = shift;

    $testCase->Name			    (extractName($testCase->Name));
    $testCase->TestNumber		(extractTestNumber($testCase->Name));
    $testCase->TopTag			(extractTopTag($testCase->Name));
    $testCase->BottomTag		(extractBottomTag($testCase->BottomTag));
    $testCase->Description      (extractDescription($testCase->Description));
    $testCase->CallSut          (extractCallSut($testCase->CallSut));
    $testCase->DesignItem       (convertCallSut2DesignItem($testCase->CallSut));

    # PreConditions
    my @preConditions = $testCase->PreConditions;
    $testCase->ClearPreConditions;
    foreach my $preCondition (@preConditions)
    {
        $preCondition = extractPreCondition($preCondition);
        $testCase->AddPreCondition($preCondition);
    }
    
    # PostConditions
    my @postConditions = $testCase->PostConditions;
    $testCase->ClearPostConditions;
    foreach my $postCondition (@postConditions)
    {
        $postCondition = extractPostCondition($postCondition);
        $testCase->AddPostCondition($postCondition);
    }

    # TestSteps
    my @testSteps = $testCase->TestSteps;
    $testCase->ClearTestSteps;
    foreach my $testStep (@testSteps)
    {
        my $callSut = extractCallSut($testStep);
        $testStep = convertCallSut2TestStep($callSut);
        $testCase->AddTestStep($testStep);
    }

    # ExpectedResults
    my @expectedResults = $testCase->ExpectedResults;
    $testCase->ClearExpectedResults;
    foreach my $expectedResult (@expectedResults)
    {
        $expectedResult = extractExpectedResult($expectedResult);
        $testCase->AddExpectedResult($expectedResult);
    }

    # ExpectedCalls --> PreConditions
    my @expectedCalls = extractExpectedCalls($testCase->ExpectedCalls);
    foreach my $expectedCall (@expectedCalls)
    {
        my $preCondition = convertExpectedCall2PreCondition($expectedCall);
        $testCase->AddPreCondition($preCondition);
    }

    push @testCases, $testCase;
}

sub transformPreCondition
{
    my $preCondition = shift;
    my $preConditionTrans = $preCondition;

    my @words = grep { $_ ne "" } (split /[,]/, $preCondition);
    my $var = $words[0];
    my $ind = $words[1];
    my $val = $words[2];

    if ($ind eq "=") { $preConditionTrans = "Set $var as $val"; }
    elsif ($ind eq "#")
    {
        if ($val ne "default") { $preConditionTrans = "Function $var returns $val"; }
        else  { $preConditionTrans = "Call function $var"; }
    }

    return $preConditionTrans;
}

sub transformPostCondition
{
    my $postCondition = shift;
    my $postConditionTrans = $postCondition;

    my @words = grep { $_ ne "" } (split /[,]/, $postCondition);
    my $var = $words[0];
    my $ind = $words[1];
    my $val = $words[2];

    # Remove prefix "expected_"
    if ($var =~ /expected_/)
    {
        @words = grep { $_ ne "" } (split /expected_/, $var);
        $var = pop @words;
    }

    if ($ind eq "=") { $postConditionTrans = "$var as $val"; }
    elsif ($ind eq "#") { $postConditionTrans = "Function $var returns $val"; }

    return $postConditionTrans;
}

sub transformExpectedResult
{
    my $expectedResult = shift;
    my $callSut = shift;
    my $expectedResultTrans = $expectedResult;

    my @words = grep { $_ ne "" } (split /[,]/, $expectedResult);
    my $var = $words[0];
    my $ind = $words[1];
    my $val = $words[2];

    if ($ind eq "=") { $expectedResultTrans = "$var as $val"; }

    my @wordsCallSut = grep { $_ ne "" } (split /[,]/, $callSut);
    my $retVarCallSut = $wordsCallSut[0];
    my $indCallSut = $wordsCallSut[1];
    my $fnxCallSut = $wordsCallSut[2];

    if ($retVarCallSut eq $var) { $expectedResultTrans = "Function $fnxCallSut returns $val"; }

    return $expectedResultTrans;
}

sub transformTestStep
{
    my $testStep = shift;
    my $transformTestStep = "Call function $testStep";
    return $transformTestStep;
}

sub convertWindowsPath2UnixPath
{
    my $windowsPath = shift;
    my $unixPath = $windowsPath;

    if ($windowsPath =~ /\\/)
    {
        my @words = grep { $_ ne "" } (split /[\\]/, $windowsPath);
        $unixPath = join "/", @words;
        if ($verboseOn) { print "convertWindowsPath2UnixPath: \$unixPath: ", $unixPath, "\n"; }
        print LOG "convertWindowsPath2UnixPath: \$unixPath: ", $unixPath, "\n";
    }
    
    return $unixPath;
}

sub getFileExtension
{
    my $filePath = shift;
    my @words = grep { $_ ne "" } (split /[\/\.]/, $filePath);
    my $fileExtension = pop @words;
    if ($verboseOn) { print "getFileExtension: \$fileExtension: ", $fileExtension, "\n"; }
    print LOG "getFileExtension: \$fileExtension: ", $fileExtension, "\n";
    return $fileExtension;
}

sub isCSource
{
    my $file = shift;
    my $ext = getFileExtension($file);
    if ($ext eq "c") { return 1; }
    else { return 0; }
}

sub showHelps
{
    print <<EOF;

UTSG - Unit Test Specification Generator
Version 1.1

Usage:
    utsg.pl -ut <ut_source_file> [options]

Command line options:
    -ut         Specify UT source file path.
    -sut        Specify SUT source file path.
    -out_dir    Specify an output directory.
    -show_word  Show Microsoft Word window during output generation.
    -verbose    Print out internal variables.
    -help       Show helps.

UTSG accepts for both absolute path and relative path when specifying UT source
file path, SUT source file path and output directory path. Both Windows-like
path and UNIX-like path are accepted. Only C source files are accepted for –ut
and –sut.

By default, UTSG treats the current directory as the output directory if the
option –out_dir is not used. The output file name is the same with the UT
source file name but with the different file extension (*.docx).

EOF
}
