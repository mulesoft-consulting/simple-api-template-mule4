%dw 2.0
import * from dw::test::Asserts
---
payload must [
  beObject(),
  $[*"success"] must haveSize(1),
  $[*"apiName"] must haveSize(1),
  $[*"version"] must haveSize(1),
  $[*"timestamp"] must haveSize(1),
  $[*"success"][0] must equalTo(true),
  $[*"apiName"][0] must equalTo("test-status-api"),
  $[*"version"][0] must equalTo("1.0.0")
]