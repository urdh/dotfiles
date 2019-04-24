function enable_crash_reporting
	launchctl load -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
           sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist
end
