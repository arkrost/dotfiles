import { realpathSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

function canonicalPath(path: string): string {
	try {
		return realpathSync(path);
	} catch {
		return resolve(path);
	}
}

function hasMarker(cwd: string): boolean {
	try {
		return statSync(join(dirname(cwd), ".no-project-instructions")).isFile();
	} catch {
		return false;
	}
}

export default function noProjectInstructions(pi: ExtensionAPI) {
	pi.on("before_agent_start", (event) => {
		const options = event.systemPromptOptions;
		const cwd = canonicalPath(options.cwd);
		if (!hasMarker(cwd)) return;
		const agentDir = canonicalPath(getAgentDir());

		// Keep global and ancestor instructions, but not those in the working directory.
		if (options.contextFiles) {
			options.contextFiles = options.contextFiles.filter((file) => {
				const directory = canonicalPath(dirname(file.path));
				return directory === agentDir || directory !== cwd;
			});
		}
		if (options.skills) {
			options.skills = options.skills.filter((skill) => skill.sourceInfo.scope !== "project");
		}
	});
}
