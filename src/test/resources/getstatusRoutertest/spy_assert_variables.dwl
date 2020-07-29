%dw 2.0
import * from dw::test::Asserts
---
vars must [
  haveKey('flowName'),
  $['flowName'] must equalTo("status")
]