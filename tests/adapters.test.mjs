import test from 'node:test';
import assert from 'node:assert/strict';
import { DebugToolsAiPlugin } from '../.opencode/plugins/debug-tools-ai.js';
import piExtension from '../.pi/extensions/debug-tools-ai/index.js';

test('OpenCode discovers the one workflow skill and injects a bounded hint only once', async () => {
  const plugin = await DebugToolsAiPlugin();
  const config = {};
  await plugin.config(config);
  await plugin.config(config);
  assert.equal(config.skills.paths.length, 1);
  const output = { messages: [{ info: { role: 'user' }, parts: [{ type: 'text', text: 'Explain Fibonacci' }] }] };
  const transform = plugin['experimental.chat.messages.transform'];
  await transform({}, output);
  assert.equal(output.messages[0].parts.length, 1);
  output.messages[0].parts[0].text = 'Use DebugTools to reload code, invoke once and recover its result';
  await transform({}, output);
  await transform({}, output);
  assert.equal(output.messages[0].parts.length, 2);
  const hint = output.messages[0].parts[0].text;
  assert.ok(hint.length < 1000);
  assert.ok(hint.includes('debug-tools skill'));
  assert.ok(!hint.includes('## Shared workflow'));
});

test('Pi sends a composite request to one skill without forcing a topic or loading every reference', async () => {
  const sent = [];
  const notices = [];
  let command;
  piExtension({ registerCommand: (_name, value) => { command = value; }, sendUserMessage: (...message) => sent.push(message) });
  const context = { ui: { notify: (...message) => notices.push(message) } };
  await command.handler(' ', context);
  assert.equal(sent.length, 0);
  assert.equal(notices.length, 1);
  const request = '启动测试配置，热重载后调用一次，超时就找回原结果并检查 SQL';
  await command.handler(request, context);
  assert.equal(sent.length, 1);
  assert.ok(sent[0][0].includes('name: debug-tools\n'));
  assert.ok(sent[0][0].includes(request));
  assert.ok(sent[0][0].includes('references/run-and-hotswap.md'));
  assert.ok(!sent[0][0].includes('# Bounded live observation'));
  assert.equal(sent[0][1].deliverAs, 'followUp');
});
