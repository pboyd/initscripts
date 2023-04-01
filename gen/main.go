package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

type Opts struct {
	ParamType string

	Username           string
	CopyRootPassword   bool
	AuthorizedKeysPath string
	RemoveUser         string

	WireGuard        bool
	WireGuardIP      string
	WireGuardPeerKey string
	WireGuardPeerIP  string
	WireGuardOutput  string
	NAT              bool

	UFW bool
}

var opts Opts
var rootCmd *cobra.Command

func init() {
	rootCmd = &cobra.Command{
		Use:   "gen",
		Short: "init script generator",
		Run:   generate,
	}

	flags := rootCmd.Flags()

	flags.StringVar(&opts.ParamType, "param-type", "vars", `how to define params for the generated script (options are "vars" or "linode-udf"`)

	flags.StringVar(&opts.Username, "username", "user", "default username")
	flags.BoolVar(&opts.CopyRootPassword, "copy-root-password", false, "if set, copies root's password to the admin user")
	flags.StringVar(&opts.AuthorizedKeysPath, "authorized-keys-path", "/home/admin/.ssh/authorized_keys", "file path on the server where the authorized keys will be")
	flags.StringVar(&opts.RemoveUser, "remove-user", "", "remove the user with this name")

	flags.BoolVar(&opts.WireGuard, "wireguard", true, "whether or not to configure WireGuard")
	flags.StringVar(&opts.WireGuardIP, "wireguard-ip", "192.168.50.2/24", "default IP address to assign to the WireGuard interface")
	flags.StringVar(&opts.WireGuardPeerKey, "wireguard-peer-key", "iupfsx9fgp4erSmjmByPEjAoZPdqNat2Zgq1c5qPwig=", "default public key for the WireGuard peer")
	flags.StringVar(&opts.WireGuardPeerIP, "wireguard-peer-ip", "192.168.50.1/32", "default IP address for the WireGuard peer")
	flags.StringVar(&opts.WireGuardOutput, "wireguard-output", "console", "how to output the generated WireGuard peer config (console or stdout)")
	flags.BoolVar(&opts.NAT, "nat", false, "when set, uses a placeholder for the sample peer config instead of trying to get the public IP.")

	flags.BoolVar(&opts.UFW, "ufw", false, "whether or not to configure the UFW firewall")
}

func main() {
	err := rootCmd.Execute()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func generate(cmd *cobra.Command, args []string) {
	if err := tmpl.Execute(os.Stdout, &opts); err != nil {
		fmt.Fprintf(os.Stderr, "template error: %v\n", err)
		os.Exit(1)
	}
}
