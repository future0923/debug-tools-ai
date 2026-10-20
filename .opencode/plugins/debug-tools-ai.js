/**
 * DebugTools AI plugin for OpenCode.
 *
 * Adds this repository's skills directory to OpenCode skill discovery and
 * injects a short skill-routing hint for relevant requests when plugin hooks are
 * available.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const DebugToolsAiPlugin = async () => {
  const candidateRoots = [
    path.resolve(__dirname, '../..'),
    path.resolve(__dirname, '..'),
    path.resolve(__dirname, '../debug-tools-ai'),
    path.resolve(__dirname, '../../debug-tools-ai'),
    path.resolve(__dirname, '../opencode/debug-tools-ai')
  ];

  const packageRoot = candidateRoots.find((candidate) => {
    return fs.existsSync(path.join(candidate, 'skills/debug-tools/SKILL.md'));
  }) || path.resolve(__dirname, '../debug-tools-ai');

  const skillsDir = path.join(packageRoot, 'skills');
  // Skill discovery loads the relevant instructions on demand, including after install.
  const bootstrap = `<DEBUG_TOOLS_AI>
Load the discovered debug-tools skill to complete the requested Java debugging
workflow. It connects target discovery, startup/readiness/reload when authorized,
invocation, original-result recovery, evidence and cleanup. Read conditional
references only when needed and use only tools in the current MCP catalog.
</DEBUG_TOOLS_AI>`;

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },

    'experimental.chat.messages.transform': async (_input, output) => {
      if (!output.messages.length) return;
      const firstUser = [...output.messages].reverse().find((message) => message.info.role === 'user');
      if (!firstUser || !firstUser.parts.length) return;
      const text = firstUser.parts.filter((part) => part.type === 'text').map((part) => part.text).join(' ');
      if (!/debug[ -]?tools|hotswap|invoke_java_method|附着.*JVM|热重载/i.test(text)) return;

      const alreadyInjected = firstUser.parts.some((part) => {
        return part.type === 'text' && part.text.includes('<DEBUG_TOOLS_AI>');
      });
      if (alreadyInjected) return;

      const ref = firstUser.parts[0];
      firstUser.parts.unshift({ ...ref, type: 'text', text: bootstrap });
    }
  };
};
