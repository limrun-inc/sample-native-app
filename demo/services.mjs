// Stand-ins for the two services the preview reaches through the tunnel: the
// staging orders API, whose hostname resolves only inside this network, and
// the pull request's new ETA service, which runs on this laptop.
import { lookup } from 'node:dns/promises';
import { createServer } from 'node:http';
import { networkInterfaces } from 'node:os';
import { createInterface } from 'node:readline';

const stagingHost = 'api.staging.internal';

const orders = [
  {
    id: '1042',
    customer: 'Maya Chen',
    status: 'Out for delivery',
    total: 18.5,
    items: [
      { name: 'Oat milk latte', quantity: 2 },
      { name: 'Almond croissant', quantity: 1 },
    ],
  },
  {
    id: '1041',
    customer: 'Jonas Weber',
    status: 'Preparing',
    total: 32,
    items: [
      { name: 'Margherita pizza', quantity: 1 },
      { name: 'Caesar salad', quantity: 1 },
      { name: 'Sparkling water', quantity: 2 },
    ],
  },
  {
    id: '1040',
    customer: 'Priya Nair',
    status: 'Preparing',
    total: 12.75,
    items: [{ name: 'Pad thai', quantity: 1 }],
  },
  {
    id: '1039',
    customer: 'Tom Alvarez',
    status: 'Confirmed',
    total: 24.9,
    items: [
      { name: 'Burrito bowl', quantity: 2 },
      { name: 'Horchata', quantity: 1 },
    ],
  },
];

const estimates = {
  1042: { minutes: 12, courier: 'Sam' },
  1041: { minutes: 25, courier: 'Lena' },
  1040: { minutes: 31, courier: 'Ade' },
  1039: { minutes: 40, courier: 'Kai' },
};

// Domain selectors never dial loopback, so the hostname must map to this
// Mac's LAN IP. A missing, loopback or stale mapping fails here, not mid-demo.
async function stagingAddress() {
  const lan = Object.values(networkInterfaces())
    .flat()
    .filter((iface) => iface.family === 'IPv4' && !iface.internal)
    .map((iface) => iface.address);
  const address = await lookup(stagingHost, { family: 4 }).then(
    (result) => result.address,
    () => undefined,
  );
  if (!lan.includes(address)) {
    throw new Error(
      `${stagingHost} resolves to ${address ?? 'nothing'}. Point it at this Mac's LAN IP (${lan.join(' or ')}) in /etc/hosts.`,
    );
  }
  return address;
}

const services = {
  staging: {
    port: 4200,
    hosts: [
      await stagingAddress().catch((error) => {
        console.error(error.message);
        process.exit(1);
      }),
    ],
    routes: [
      [/^\/orders$/, () => orders],
      [/^\/orders\/(\w+)$/, (id) => orders.find((order) => order.id === id)],
    ],
  },
  eta: {
    port: 4100,
    // localhost:4100 covers both loopback addresses.
    hosts: ['127.0.0.1', '::1'],
    routes: [[/^\/eta\/(\w+)$/, (id) => estimates[id]]],
  },
};

const running = new Map();

function handler(name, routes) {
  return (request, response) => {
    console.log(`  ${new Date().toLocaleTimeString()}  ${name.padEnd(7)}  ${request.method} ${request.url}`);
    const path = new URL(request.url, 'http://localhost').pathname;
    let body;
    for (const [pattern, resolve] of routes) {
      const match = path.match(pattern);
      if (match) {
        body = resolve(...match.slice(1));
        break;
      }
    }
    response.statusCode = body ? 200 : 404;
    response.setHeader('cache-control', 'no-store');
    response.setHeader('content-type', 'application/json');
    response.end(JSON.stringify(body ?? { error: 'not found' }));
  };
}

async function start(name) {
  if (running.has(name)) {
    console.log(`${name} is already up`);
    return;
  }
  const { port, hosts, routes } = services[name];
  const servers = await Promise.all(
    hosts.map(
      (host) =>
        new Promise((resolve, reject) => {
          const server = createServer(handler(name, routes));
          server.once('error', reject);
          server.listen({ port, host, ipv6Only: host.includes(':') }, () => resolve(server));
        }),
    ),
  );
  running.set(name, servers);
  console.log(`${name.padEnd(7)}  up    ${name === 'staging' ? stagingHost : 'localhost'}:${port}`);
}

async function stop(name) {
  const servers = running.get(name);
  if (!servers) {
    console.log(`${name} is already down`);
    return;
  }
  running.delete(name);
  await Promise.all(
    servers.map(
      (server) =>
        new Promise((resolve) => {
          server.close(resolve);
          server.closeAllConnections();
        }),
    ),
  );
  console.log(`${name.padEnd(7)}  down`);
}

async function shutdown() {
  await Promise.all([...running.keys()].map(stop));
  process.exit(0);
}

for (const name of Object.keys(services)) {
  await start(name);
}
console.log('\nCommands: staging down | staging up | eta down | eta up | quit\n');

createInterface({ input: process.stdin }).on('line', async (line) => {
  const [name, action] = line.trim().toLowerCase().split(/\s+/);
  if (name === 'quit') {
    await shutdown();
  } else if (name in services && action === 'up') {
    await start(name);
  } else if (name in services && action === 'down') {
    await stop(name);
  } else {
    console.log('Use: staging down | staging up | eta down | eta up | quit');
  }
});

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
