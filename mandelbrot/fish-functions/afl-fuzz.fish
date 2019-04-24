function afl-fuzz --description "Turn of crash reporter when running afl-fuzz"
	set -l syslib   /System/Library
	set -l property com.apple.ReportCrash
	function __afl-fuzz_cleanup --on-process %self
		launchctl load -w $syslib/LaunchAgents/{$property}.plist
		sudo launchctl load -w $syslib/LaunchAgents/{$property}.Root.plist
	end
	launchctl unload -w $syslib/LaunchAgents/{$property}.plist
	sudo launchctl unload -w $syslib/LaunchDaemons/{$property}.Root.plist
	command afl-fuzz $argv
	launchctl load -w $syslib/LaunchAgents/{$property}.plist
	sudo launchctl load -w $syslib/LaunchAgents/{$property}.Root.plist
end
