#! /bin/bash
# OK: 1, 3, 8, 13-18, 20
# ERR: 2, 4-7, 9-12, 19
echo "(line: 1) OK stdout"
echo "(line: 2) ERR stderr" >&2
echo "(line: 3) OK stdout"
echo "(line: 4) ERR stderr" >&2
echo "(line: 5) ERR stderr" >&2
echo "(line: 6) ERR stderr" >&2
echo "(line: 7) ERR stderr" >&2
echo "(line: 8) OK stdout"
echo "(line: 9) ERR stderr" >&2
echo "(line: 10) ERR stderr" >&2
echo "(line: 11) ERR stderr" >&2
echo "(line: 12) ERR stderr" >&2
echo "(line: 13) OK stdout"
echo "(line: 14) OK stdout"
echo "(line: 15) OK stdout"
echo "(line: 16) OK stdout"
echo "(line: 17) OK stdout"
echo "(line: 18) OK stdout"
echo "(line: 19) ERR stderr" >&2
echo "(line: 20) OK stdout"