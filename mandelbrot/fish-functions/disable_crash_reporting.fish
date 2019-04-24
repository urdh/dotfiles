function disable_crash_reporting
	launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
           sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist
end
