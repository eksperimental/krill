#! /bin/bash
echo "this is ok (line: 1)"
echo "this is is error (line: 2)" >&2
echo "this is ok 2 (line: 3)"
echo "this is is error2 (line: 4)" >&2
echo "this is is error3 (line: 5)" >&2
echo "this is ok 3 (line: 6)"