/// WARNING: Like all files in the examples section, this code is unaudited
/// and should NOT be running in production. Using the code unaudited could potentially
/// result in lost of funds from hacks, and leakage of transaction amounts.

/// Module representing an example implementation for private coins.
///
/// To implement any of the methods, module defining the type for the currency
/// is expected to implement the main set of methods such as `borrow()`,
/// `borrow_mut()` and `zero()`.
module fungible_tokens::private_coin {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use fungible_tokens::private_balance::{Self, PrivateBalance, Supply};
    use sui::elliptic_curve::{Self as ec, RistrettoPoint};

    /// A private coin of type `T` worth `value`.
    /// The balance stores a RistrettoPoint that is a pedersen commitment of the coin's value.
    /// The coin may be public or private.
    struct PrivateCoin<phantom T> has key, store {
        id: UID,
        balance: PrivateBalance<T>
    }

    /// Capability allowing the bearer to mint and burn
    /// coins of type `T`. Transferable
    struct TreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: Supply<T>
    }

    // ===== Supply <-> TreasuryCap morphing and accessors =====

    /// Return the total number of `T`'s in circulation.
    public fun total_supply<T>(cap: &TreasuryCap<T>): u64 {
        private_balance::supply_value(&cap.total_supply)
    }

    /// Wrap a `Supply` into a transferable `TreasuryCap`
    public fun treasuty_from_supply<T>(total_supply: Supply<T>, ctx: &mut TxContext): TreasuryCap<T> {
        TreasuryCap<T> { id: object::new(ctx), total_supply }
    }

    /// Unwrap `TreasuryCap` getting the `Supply`
    public fun treasury_into_supply<T>(treasury: TreasuryCap<T>): Supply<T> {
        let TreasuryCap<T> { id, total_supply } = treasury;
        object::delete(id);
        total_supply
    }

    /// Get immutable reference to the treasury's `Supply`.
    public fun supply<T>(treasury: &TreasuryCap<T>): &Supply<T> {
        &treasury.total_supply
    }

    /// Get mutable reference to the treasury's `Supply`
    public fun supply_mut<T>(treasury: &mut TreasuryCap<T>): &mut Supply<T> {
        &mut treasury.total_supply
    }

    // ==== Balance <-> PrivateCoin accessors and type morphing ====

    /// Get immutable reference to the balance of a coin.
    public fun balance<T>(coin: &PrivateCoin<T>): &PrivateBalance<T> {
        &coin.balance
    }

    /// Get a mutable reference to the balance of a coin.
    public fun balance_mut<T>(coin: &mut PrivateCoin<T>): &mut PrivateBalance<T> {
        &mut coin.balance
    }

    /// Wrap a private balance into a PrivateCoin to make it transferable.
    public fun from_balance<T>(balance: PrivateBalance<T>, ctx: &mut TxContext): PrivateCoin<T> {
        PrivateCoin<T> { id: object::new(ctx), balance }
    }

    /// Destruct a PrivateCoin wrapper and keep the balance.
    public fun into_balance<T>(coin: PrivateCoin<T>): PrivateBalance<T> {
        let PrivateCoin<T> { id, balance } = coin;
        object::delete(id);
        balance
    }

    /// Take a `PrivateCoin` of `value` worth from `PrivateBalance`.
    /// Aborts if `balance.value > Open(new_commitment)`
    public fun take<T>(
        balance: &mut PrivateBalance<T>, new_commitment: RistrettoPoint, proof: vector<u8>, ctx: &mut TxContext
    ): PrivateCoin<T> {
        PrivateCoin<T> {
            id: object::new(ctx),
            balance: private_balance::split(balance, new_commitment, proof)
        }
    }

    /// Take a `PrivateCoin` of `value` worth from `PrivateBalance`.
    /// Aborts if `value > balance.value`
    public fun take_public<T>(
        balance: &mut PrivateBalance<T>, value: u64, proof: vector<u8>, ctx: &mut TxContext
    ): PrivateCoin<T> {
        PrivateCoin<T> {
            id: object::new(ctx),
            balance: private_balance::split_to_public(balance, value, proof)
        }
    }

    /// Put a `PrivateCoin<T>` into a `PrivateBalance<T>`.
    public fun put<T>(balance: &mut PrivateBalance<T>, coin: PrivateCoin<T>) {
        private_balance::join(balance, into_balance(coin));
    }

    // ==== Functionality for Coin<T> holders ====

    /// Send `c` to `recipient`
    public entry fun transfer<T>(c: PrivateCoin<T>, recipient: address) {
        transfer::transfer(c, recipient)
    }

    /// Transfer `c` to the sender of the current transaction
    public fun keep<T>(c: PrivateCoin<T>, ctx: &TxContext) {
        transfer(c, tx_context::sender(ctx))
    }

    /// Consume the coin `c` and add its value to `self`
    public entry fun join<T>(self: &mut PrivateCoin<T>, c: PrivateCoin<T>) {
        let PrivateCoin<T> { id, balance } = c;
        object::delete(id);
        private_balance::join(&mut self.balance, balance);
    }

    // ==== Registering new coin types and managing the coin supply ====

    /// Make any Coin with a zero value. Useful for placeholding
    /// bids/payments or preemptively making empty balances.
    public fun zero<T>(ctx: &mut TxContext): PrivateCoin<T> {
        PrivateCoin<T> { id: object::new(ctx), balance: private_balance::zero() }
    }

    /// Create a new currency type `T` as and return the `TreasuryCap`
    /// for `T` to the caller.
    /// NOTE: It is the caller's responsibility to ensure that
    /// `create_currency` can only be invoked once (e.g., by calling it from a
    /// module initializer with a `witness` object that can only be created in
    /// the initializer).
    public fun create_currency<T: drop>(witness: T, ctx: &mut TxContext): TreasuryCap<T> {
        TreasuryCap<T> {
            id: object::new(ctx),
            total_supply: private_balance::create_supply(witness)
        }
    }

    /// Create a coin worth `value`. and increase the total supply
    /// in `cap` accordingly.
    public fun mint<T>(
        cap: &mut TreasuryCap<T>,
        value: u64,
        ctx: &mut TxContext
    ): PrivateCoin<T> {
        PrivateCoin<T> {
            id: object::new(ctx),
            balance: private_balance::increase_supply(&mut cap.total_supply, value)
        }
    }

    /// Mint some amount of T as a `PrivateBalance` and increase the total
    /// supply in `cap` accoudingly.
    /// Aborts if `value` + `cap.total_supply` >= U64_MAX
    public fun mint_balance<T>(cap: &mut TreasuryCap<T>, value: u64): PrivateBalance<T> {
        private_balance::increase_supply(&mut cap.total_supply, value)
    }

    /// Give away the treasury cap to `recipient`
    public fun transfer_cap<T>(c: TreasuryCap<T>, recipient: address) {
        transfer::transfer(c, recipient)
    }

    // ==== Entrypoints ====

    /// Mint `amount` of `PrivateCoin` and send it to `recipient`. Invokes `mint()`.
    public entry fun mint_and_transfer<T>(
        c: &mut TreasuryCap<T>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        transfer::transfer(mint(c, amount, ctx), recipient)
    }

    /// Split coin from `slef`, the split coin will be a private coin worth the value committed by `new_commitment`,
    /// the remaining balance is left i `self`. Note that performing split on a public coin turns it into a private coin.
    public entry fun split_and_transfer<T>(
        c: &mut PrivateCoin<T>,
        new_commitment: vector<u8>,
        proof: vector<u8>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let ristretto_point = ec::new_from_bytes(new_commitment);
        transfer::transfer(take(&mut c.balance, ristretto_point, proof, ctx), recipient)
    }

    /// Split coin from `self`, the split coin will be a public coin worth `value`.
    /// the remaining balance is left in `self`. `self` should retain it's privacy option after this call.
    public entry fun split_public_and_transfer<T>(
        self: &mut PrivateCoin<T>,
        value: u64,
        proof: vector<u8>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        transfer::transfer(
            take_public(&mut self.balance, value, proof, ctx),
            recipient
        )
    }

    /// Reveals a `PrivateCoin` - allowing others to freely query the coin's balance.
    public entry fun open_coin<T>(c: &mut PrivateCoin<T>, value: u64, blinding_factor: vector<u8>) {
        private_balance::open_balance(&mut c.balance, value, blinding_factor)
    }
}
