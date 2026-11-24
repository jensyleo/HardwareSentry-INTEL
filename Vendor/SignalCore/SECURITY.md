# Security Policy

## Supported versions

Only the latest release is supported. Older tags do not receive security fixes.

## Scope

SignalCore is a local notification library. It draws banners, plays system sounds and keeps its settings
and icon choices in the host application's user defaults. It does not use the network and requires no
elevated privileges.

Relevant reports: a crash or memory-safety issue reachable from a notification's text, icon data or
image file; a code path that persists or exposes more than the host application asked it to; a flaw that
lets a notification the host or the person switched off still be shown.

## Reporting a vulnerability

Please report privately using **GitHub's "Report a vulnerability" feature** (Security tab → *Report a
vulnerability*) on this repository, instead of opening a public issue. Include the affected version and
macOS version, steps to reproduce, the expected versus actual behaviour, and the impact. You should get an
initial response within a few days; confirmed issues are fixed and credited in the release notes unless you
ask otherwise.
