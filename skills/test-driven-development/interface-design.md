# Interface Design for Testability

Follow [codebase-design](../codebase-design/SKILL.md). Good interfaces hide
implementation details and make behavior tests natural:

1. **Inject external capabilities where substitution or lifetime matters**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Keep calculations pure; make side-effect completion explicit**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

   A persistence operation may have side effects. It should return only after
   required writes finish, or explicitly hand ownership to its caller.

3. **Small surface area**
   - Expose complete operations rather than steps callers must assemble
   - Keep private helpers private; do not add exports or injection solely for tests
