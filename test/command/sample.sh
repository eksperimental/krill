#! /bin/bash
echo "this is ok (line: 1)"
echo "this is is error (line: 2)" >&2
echo "this is ok (line: 3)"
echo "this is is error (line: 4)" >&2
echo "this is is error (line: 5)" >&2
echo "this is ok (line: 6)"