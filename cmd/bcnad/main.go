package main

import (
	"fmt"
	"os"

	clienthelpers "cosmossdk.io/client/v2/helpers"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"bcna/app"
	"bcna/cmd/bcnad/cmd"
)

func main() {
	rootCmd := cmd.NewRootCmd()
	if err := svrcmd.Execute(rootCmd, clienthelpers.EnvPrefix, app.DefaultNodeHome); err != nil {
		if _, writeErr := fmt.Fprintln(rootCmd.OutOrStderr(), err); writeErr != nil {
			os.Exit(1)
		}
		os.Exit(1)
	}
}
