Krill
=====

Filter feeder for shell commands.

## Usage

feeder = Krill.new
feeder.config = [
	command_name: "htmlproof",
	command: "bundle exec htmlproof ./_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
	dir: "../",
	messages: [
		ok: "OK: Documents have been validated.",
		error: "ERROR: Documents did not validate.",
		] 
	]
defmodule Htmlproof do
	use Krill
end



htmlproof = Htmlproof.new
htmlproof.config = [
	name: "htmlproof",
	command: "bundle exec htmlproof ./_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
	dir: "../",
	messages: [
		ok: "OK: Documents have been validated.",
		error: "ERROR: Documents did not validate.",
		] 
	]