// See: http://linux.die.net/man/5/yum.conf
package main

import (
	"bufio"
	"os/exec"
	"regexp"
	"time"
)

// YumRepo represents a single Yum rpeository; typically defined in a `.repo`
// file in `/etc/yum.repos.d/`.
type YumRepo struct {
	ID            string    `json:"id",omitempty"`
	Name          string    `json:"name,omitempty"`
	Enabled       bool      `json:"enabled,omitempty"`
	Revision      string    `json:"revision,omitempty"`
	UpdateDate    time.Time `json:"updateDate,omitempty"`
	BaseURL       string    `json:"baseUrl,omitempty"`
	ExpireDate    time.Time `json:"expireDate,omitempty"`
	Filename      string    `json:"fileName,omitempty"`
	MirrorListURL string    `json:"mirrorListUrl,omitempty"`
	GPGCAKey      string    `json:"gpgCaKey,omitempty"`
	GPGCheck      bool      `json:"gpgCheck,omitempty"`
	GPGKeyPath    string    `json:"gpgKeyPath,omitempty"`
}

// yumTimeLayout is the Date/Time format used by Yum in its output
var yumTimeLayout = "Mon Jan 2 15:04:05 2006"

// fieldPattern is the regex pattern used to match output from `yum repolist -v`
var fieldPattern = regexp.MustCompile("^Repo-(\\w*)\\s*:\\s*(.*)$")

func GetInstalledRepos() ([]YumRepo, error) {
	repos := make([]YumRepo, 0)

	// get repo list from yum
	cmd := exec.Command("yum", "repolist", "all", "-v")

	// create reader for the command's stdout
	reader, err := cmd.StdoutPipe()
	if err != nil {
		return repos, err
	}
	scanner := bufio.NewScanner(reader)

	// parse output in a new thread
	go func() {
		var repo *YumRepo = nil
		for scanner.Scan() {
			line := scanner.Text()
			matches := fieldPattern.FindAllStringSubmatch(line, -1)

			// is this line a field match?
			if len(matches) > 0 {
				// create a new repo
				if repo == nil {
					repo = &YumRepo{}
				}

				key := matches[0][1]
				val := matches[0][2]

				// update current repo
				switch key {
				case "id":
					repo.ID = val

				case "name":
					repo.Name = val

				case "status":
					repo.Enabled = val == "enabled"

				case "revision":
					repo.Revision = val

				case "baseurl":
					repo.BaseURL = val

				case "filename":
					repo.Filename = val

				case "updated":
					t, _ := time.Parse(yumTimeLayout, val)
					repo.UpdateDate = t

				case "mirrors":
					repo.MirrorListURL = val
				}
			} else {
				// current line is not a repo field
				if repo != nil {
					repos = append(repos, *repo)
					repo = nil
				}
			}
		}
	}()

	// execute
	err = cmd.Start()
	if err != nil {
		return repos, err
	}

	// wait for process to finish
	err = cmd.Wait()
	if err != nil {
		return repos, err
	}

	return repos, nil
}
