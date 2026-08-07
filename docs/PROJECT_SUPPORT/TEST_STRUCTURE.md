# Test Layout

Recommended test targets:

```text
FSDUnitTests
FSDIntegrationTests
FSDUITests
```

Suggested fixture folder:

```text
Tests/Fixtures/
├── empty/
├── simple_equal_left/
├── simple_equal_right/
├── added_removed_changed_left/
├── added_removed_changed_right/
├── symlinks/
├── unicode_names/
├── inaccessible/
└── large_generated/
```

Critical tests are defined in `TEST_PLAN.md`.
