module defi::subscription {
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;

    /// For when subscription object no longer has uses.
    const ENoUses: u64 = 0;

    /// Owned object from which singleUses are spawn.
    struct Subscription<phantom T> has key {
        id: UID,
        uses: u64
    }

    /// A single use potato to authorize actions
    struct SingleUse<phantom T> {

    }

    // ========= Default Functions =========

    /// Public view for the `Subscription`. `uses` field.
    public fun uses<T>(s: &Subscription<T>): u64 {
        s.uses
    }

    /// If `Subscription` is owned, create `SingleUse` (hot potato) to use in the service.
    public fun use_pass<T>(s: &mut Subscription<T>): SingleUse<T> {
        assert!(s.uses != 0, ENoUses);
        s.uses = s.uses - 1;
        SingleUse {}
    }

    /// Burn a subscription without checking for number of uses. Allows Sui storage refunds
    /// when subscription is no longer needed.
    public entry fun destroy<T>(s: Subscription<T>) {
        let Subscription { id, uses: _ } = s;
        object::delete(id);
    }

    // ========= Implementable Functions =============

    /// Function to issue new `Subscription` with a specified number of uses.
    /// Implementable by an external module with a witness parameter T. Number
    /// of uses is determined by the actual implementation.
    public fun isses_subscription<T: drop>(_w: T, uses: u64, ctx: &mut TxContext): Subscription<T> {
        Subscription {
            id: object::new(ctx),
            uses
        }
    }

    /// Increase number of uses in the subscription.
    /// Implementable by an external module with a witness parameter T.
    public fun add_uses<T: drop>(_w: T, s: &mut Subscription<T>, uses: u64) {
        s.uses = s.uses + uses;
    }

    /// Confirm a use of a pass. Verified by the module that implements "Subscription API".
    /// Implementable by an external module with a witness parameter T. Confirmation is only
    /// available if the third party implements it and recognizes the use.
    public fun confirm_use<T: drop>(_w: T, pass: SingleUse<T>) {
        let SingleUse {  } = pass;
    }

    /// Allow applications customize transferability of the `Subscription`.
    /// Implementable by an external module with a witness parameter T.
    /// Module can define whether a `Subscription` can be transferred to another account
    /// or not. Omitting this implementation will mean that the `Subscription` can not be transferred.
    public fun transfer<T: drop>(_w: T, s: Subscription<T>, to: address) {
        transfer::transfer(s, to);
    }
}
