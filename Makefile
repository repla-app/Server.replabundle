.PHONY: ci ac autocorrect lint runtime recompile_fsevents bundle_update remove_symlinks loc

ci: gem_install lint
ac: autocorrect

lint:
	bundle exec rubocop

autocorrect:
	bundle exec rubocop -a

test:
	./Contents/Resources/test/run_tests.sh

loc:
	cloc --vcs=git --exclude-dir=bundle,.bundle

gem_install:
	bundle install --path vendor/bundle

bundle_update:
	cd ./Contents/Resources/ &&\
		bundle update repla --full-index &&\
		bundle update &&\
		bundle clean &&\
		bundle install --standalone

patch: remove_symlinks recompile_fsevents sign_runtime

sign_runtime:
	# `fsevent_watch` fails notarization without the hardened runtime enabled
	codesign --force --options runtime --sign "Developer ID Application" \
		Contents/Resources/bundle/ruby/2.4.0/gems/rb-fsevent-0.10.3/bin/fsevent_watch

recompile_fsevents:
	cd Contents/Resources/bundle/ruby/2.4.0/gems/rb-fsevent-0.10.3/ext/ && rake

remove_symlinks:
	# This was used to fix an issue where symlinks were causing the app to
	# be quarantined by macOS Gatekeeper, this isn't run automatically but
	# documents how the symlinks were deleted.
	find ./Contents/Resources/bundle/ruby/2.4.0/gems/ffi-1.11.3/ext/ffi_c/libffi-x86_64-darwin18/ -type l -delete
