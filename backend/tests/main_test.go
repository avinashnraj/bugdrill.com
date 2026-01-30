package tests

import (
	"os"
	"testing"

	"github.com/bugdrill/backend/tests/steps"
	"github.com/cucumber/godog"
	"github.com/cucumber/godog/colors"
)

var opts = godog.Options{
	Output: colors.Colored(os.Stdout),
	Format: "pretty",
	Paths:  []string{"features"},
}

func TestFeatures(t *testing.T) {
	o := opts
	o.TestingT = t

	suite := godog.TestSuite{
		Name:                "bugdrill",
		ScenarioInitializer: steps.InitializeScenario,
		Options:             &o,
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}
