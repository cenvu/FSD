// FSD's bounded stdin-only adapter. It has no classified-source capability.
package main

import (
	"bytes"
	"encoding/json"
	"io"
	"os"

	"github.com/h2non/filetype"
	"github.com/h2non/filetype/types"
)

const maximumInput = 4096
const detectorVersion = "github.com/h2non/filetype@v1.1.3"

type envelope struct {
	SchemaVersion   int      `json:"schemaVersion"`
	ResultKind      string   `json:"resultKind"`
	DetectedType    *string  `json:"detectedType"`
	MIMEType        *string  `json:"mimeType"`
	Confidence      *float64 `json:"confidence"`
	DetectorVersion *string  `json:"detectorVersion"`
	ModelVersion    *string  `json:"modelVersion"`
}

// Indirect matching keeps the single upstream-call boundary observable in the
// shipped executable. No alternate matcher or priority policy is installed.
func classify(input []byte, match func([]byte) (types.Type, error)) envelope {
	result := envelope{SchemaVersion: 1, ResultKind: "failed"}
	if len(input) > maximumInput {
		return result
	}
	if len(input) > 0 && len(input) <= 513 && bytes.HasPrefix(input, []byte{0xd0, 0xcf, 0x11, 0xe0}) {
		result.ResultKind = "no_match"
		return result
	}
	kind, err := match(input)
	if len(input) == 0 && kind == types.Unknown && err == filetype.ErrEmptyBuffer {
		result.ResultKind = "no_match"
		return result
	}
	if err != nil {
		return result
	}
	if kind == types.Unknown {
		result.ResultKind = "no_match"
		return result
	}
	result.ResultKind = "classified"
	result.DetectedType = &kind.Extension
	if kind.MIME.Value != "" {
		result.MIMEType = &kind.MIME.Value
	}
	version := detectorVersion
	result.DetectorVersion = &version
	return result
}

func main() {
	result := envelope{SchemaVersion: 1, ResultKind: "failed"}
	if len(os.Args) == 1 {
		input, err := io.ReadAll(io.LimitReader(os.Stdin, maximumInput+1))
		if err == nil {
			result = classify(input, filetype.Match)
		}
	}
	// Exactly one flat metadata envelope; no sampled bytes or diagnostics.
	_ = json.NewEncoder(os.Stdout).Encode(result)
}
