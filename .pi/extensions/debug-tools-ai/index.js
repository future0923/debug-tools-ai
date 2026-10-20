import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');

/** One skill owns the complete workflow; the request determines which references to load. */
export default function debugToolsExtension(pi) {
  pi.registerCommand('debug-tools', {
    description: 'Use DebugTools: /debug-tools <Java debugging request>',
    handler: async (args, ctx) => {
      const request = args.trim();
      if (!request) {
        ctx.ui.notify('Usage: /debug-tools <Java debugging request>', 'info');
        return;
      }
      const skillPath = path.join(root, 'skills/debug-tools/SKILL.md');
      let instructions;
      try { instructions = fs.readFileSync(skillPath, 'utf8'); }
      catch (error) {
        ctx.ui.notify(`DebugTools skill is unavailable: ${error.message}`, 'error');
        return;
      }
      pi.sendUserMessage(`Use the DebugTools skill at ${skillPath}. Relative references resolve beside that file.\n\n${instructions}\n\nUser request: ${request}`, { deliverAs: 'followUp' });
    },
  });
}
