const orders = [
  { id: "o1", customerId: "c1" },
  { id: "o2", customerId: "c2" },
];

const customers = [
  { id: "c1", name: "Ada" },
  { id: "c2", name: "Linus" },
];

// Enrich each order with its customer record.
const enriched = orders.map((order) => ({
  ...order,
  customer: customers.find((customer) => customer.id === order.customerId),
}));

module.exports = { enriched };
