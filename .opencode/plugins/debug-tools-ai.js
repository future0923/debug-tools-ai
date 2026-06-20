/**
 * DebugTools AI plugin for OpenCode.
 *
 * Adds this repository's skills directory to OpenCode skill discovery and
 * injects a compact DebugTools workflow bootstrap when plugin hooks are
 * available.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let bootstrapCache;

export const DebugToolsAiPlugin = async () => {
  const candidateRoots = [
    path.resolve(__dirname, '../..'),
    path.resolve(__dirname, '..'),
    path.resolve(__dirname, '../debug-tools-ai'),
    path.resolve(__dirname, '../../debug-tools-ai'),
    path.resolve(__dirname, '../opencode/debug-tools-ai')
  ];

  const packageRoot = candidateRoots.find((candidate) => {
    return fs.existsSync(path.join(candidate, 'skills/debug-tools-method-invocation/SKILL.md'));
  }) || path.resolve(__dirname, '../debug-tools-ai');

  const skillsDir = path.join(packageRoot, 'skills');
  const workflowPath = path.join(packageRoot, 'docs/workflow.md');

  const getBootstrapContent = () => {
    if (bootstrapCache !== undefined) return bootstrapCache;

    if (!fs.existsSync(workflowPath)) {
      bootstrapCache = null;
      return bootstrapCache;
    }

    const workflow = fs.readFileSync(workflowPath, 'utf8');
    bootstrapCache = `<DEBUG_TOOLS_AI>
Use DebugTools AI when the user asks to inspect DebugTools connections, attach a JVM, generate method arguments, invoke Java methods, list run configurations, or start a run configuration with DebugTools Hotswap.

${workflow}
</DEBUG_TOOLS_AI>`;
    return bootstrapCache;
  };

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },

    'experimental.chat.messages.transform': async (_input, output) => {
      const bootstrap = getBootstrapContent();
      if (!bootstrap || !output.messages.length) return;

      const firstUser = output.messages.find((message) => message.info.role === 'user');
      if (!firstUser || !firstUser.parts.length) return;

      const alreadyInjected = firstUser.parts.some((part) => {
        return part.type === 'text' && part.text.includes('<DEBUG_TOOLS_AI>');
      });
      if (alreadyInjected) return;

      const ref = firstUser.parts[0];
      firstUser.parts.unshift({ ...ref, type: 'text', text: bootstrap });
    }
  };
};
