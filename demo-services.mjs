import { createServer } from 'node:http';
import { createInterface } from 'node:readline';

const definitions = {
  api: {
    port: 4100,
    body: {
      service: 'local-api',
      message: 'Customer API reached on this Mac',
    },
  },
  dev: {
    port: 3000,
    body: {
      service: 'dev-server',
      message: 'Local dev server reached on this Mac',
    },
  },
};

const listeners = new Map();

function handler(name, body) {
  return (request, response) => {
    const now = new Date().toLocaleTimeString();
    console.log(`  ${now}  ${name.padEnd(3)}  ${request.url}`);
    response.setHeader('cache-control', 'no-store');
    response.setHeader('content-type', 'application/json');
    response.end(JSON.stringify(body));
  };
}

async function listen(server, options) {
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(options, () => {
      server.off('error', reject);
      resolve();
    });
  });
}

async function start(name) {
  if (listeners.has(name)) {
    console.log(`${name} is already up`);
    return;
  }
  const { port, body } = definitions[name];
  const serve = handler(name, body);
  const ipv4 = createServer(serve);
  const ipv6 = createServer(serve);
  await listen(ipv4, { port, host: '127.0.0.1' });
  await listen(ipv6, { port, host: '::1', ipv6Only: true });
  listeners.set(name, [ipv4, ipv6]);
  console.log(`${name} up   http://localhost:${port}`);
}

async function stop(name) {
  const servers = listeners.get(name);
  if (!servers) {
    console.log(`${name} is already down`);
    return;
  }
  await Promise.all(
    servers.map(
      (server) =>
        new Promise((resolve) => {
          server.close(() => resolve());
          server.closeAllConnections();
        }),
    ),
  );
  listeners.delete(name);
  console.log(`${name} down`);
}

function status() {
  for (const [name, { port }] of Object.entries(definitions)) {
    console.log(`${listeners.has(name) ? '●' : '○'} ${name.padEnd(3)} localhost:${port}`);
  }
}

async function shutdown() {
  await Promise.all([...listeners.keys()].map(stop));
  process.exit(0);
}

await Promise.all(Object.keys(definitions).map(start));
console.log('\nCommands: api down | api up | dev down | dev up | status | quit\n');
status();

const input = createInterface({ input: process.stdin, output: process.stdout });
input.on('line', async (line) => {
  const [name, action] = line.trim().toLowerCase().split(/\s+/);
  if (name === 'status') {
    status();
  } else if (name === 'quit' || name === 'q') {
    await shutdown();
  } else if (name in definitions && action === 'up') {
    await start(name);
  } else if (name in definitions && action === 'down') {
    await stop(name);
  } else {
    console.log('Use: api down | api up | dev down | dev up | status | quit');
  }
});

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
