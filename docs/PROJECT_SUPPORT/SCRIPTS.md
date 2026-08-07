# Scripts

Reserved for deterministic development and release helpers, such as:

- database schema validation;
- generated large-tree test fixtures;
- source-volume read-only audit;
- packaging and notarization;
- release checksum generation.

Scripts must never modify scanned test media unless the script is explicitly a fixture generator operating inside a disposable fixture directory.
