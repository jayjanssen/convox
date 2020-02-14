package console

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"

	"github.com/convox/convox/pkg/token"
	"github.com/convox/convox/sdk"
	"github.com/convox/stdcli"
	"github.com/convox/stdsdk"
)

var (
	reSessionAuthentication = regexp.MustCompile(`^Session path="([^"]+)" token="([^"]+)"$`)
)

type AuthenticationError struct {
	error
}

func (ae AuthenticationError) AuthenticationError() error {
	return ae.error
}

type session struct {
	ID string `json:"id"`
}

func Authenticator(c *stdcli.Context) stdsdk.Authenticator {
	return func(cl *stdsdk.Client, res *http.Response) (http.Header, error) {
		m := reSessionAuthentication.FindStringSubmatch(res.Header.Get("WWW-Authenticate"))
		if len(m) < 3 {
			return nil, nil
		}

		body := []byte{}
		headers := map[string]string{}

		if m[2] == "true" {
			ares, err := cl.GetStream(m[1], stdsdk.RequestOptions{})
			if err != nil {
				return nil, err
			}
			defer ares.Body.Close()

			dres, err := ioutil.ReadAll(ares.Body)
			if err != nil {
				return nil, err
			}

			c.Writef("Waiting for security token... ")

			data, err := token.Authenticate(dres)
			if err != nil {
				return nil, AuthenticationError{err}
			}

			c.Writef("<ok>OK</ok>\n")

			body = data
			headers["Challenge"] = ares.Header.Get("Challenge")
		}

		var s session

		ro := stdsdk.RequestOptions{
			Body:    bytes.NewReader(body),
			Headers: stdsdk.Headers(headers),
		}

		if err := cl.Post(m[1], ro, &s); err != nil {
			fmt.Printf("err: %+v\n", err)
			return nil, err
		}

		if s.ID == "" {
			return nil, fmt.Errorf("invalid session")
		}

		if err := c.SettingWriteKey("session", cl.Endpoint.Host, s.ID); err != nil {
			return nil, err
		}

		h := http.Header{}

		h.Set("Session", s.ID)

		return h, nil
	}
}

func Session(c *stdcli.Context) sdk.SessionFunc {
	return func(cl *sdk.Client) string {
		sid, _ := c.SettingReadKey("session", cl.Endpoint.Host)
		return sid
	}
}
