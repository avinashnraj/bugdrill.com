package main

import (
	"os"

	"github.com/bugdrill/backend/tests"
	"github.com/cucumber/godog"
)

func main() {
	opts := godog.Options{
		Format:   "pretty",
		Paths:    []string{"features"},
		TestingT: nil,
	}

	status := godog.TestSuite{
		Name:                "bugdrill Functional Tests",
		ScenarioInitializer: tests.InitializeScenario,
		Options:             &opts,
	}.Run()

	os.Exit(status)
}
