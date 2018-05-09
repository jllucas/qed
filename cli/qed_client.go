package cli

import (
	"bufio"
	"encoding/json"
	"os"

	"github.com/spf13/cobra"

	"qed/log"
)

func newClientCommand(ctx *Context) *cobra.Command {

	cmd := &cobra.Command{
		Use:   "client",
		Short: "Client mode for qed",
		Long:  `Client process for emitting events to a qed server`,
		RunE: func(cmd *cobra.Command, args []string) error {

			scanner := bufio.NewScanner(os.Stdin)
			for scanner.Scan() {
				snapshot, _ := ctx.client.Add(scanner.Text())

				resp, err := json.Marshal(&snapshot)
				if err != nil {
					panic(err)
				}
				log.Infof("%s\n", resp)

			}

			return nil
		},
	}

	return cmd
}
