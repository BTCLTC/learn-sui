module basics::sandwich {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Ham has key {
        id: UID,
    }

    struct Bread has key {
        id: UID
    }

    struct Sandwich has key {
        id: UID,
    }

    /// This capability allows the owner to withdraw profits
    struct GroceryOwnerCapability has key {
        id: UID,
    }

    /// Grocery is created on module init
    struct Grocery has key {
        id: UID,
        profits: Balance<SUI>
    }

    /// Price for ham
    const HAM_PRICE: u64 = 10;
    /// Price for bread
    const BREAD_PRICE: u64 = 2;

    /// Not enough funds to pay for the good in question
    const EInsuffilientFunds: u64 = 0;
    /// Nothing to withdraw
    const ENoProfits: u64 = 1;

    /// On module init, create a grocery
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Grocery {
            id: object::new(ctx),
            profits: balance::zero<SUI>()
        });

        transfer::transfer(GroceryOwnerCapability {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    /// Exchange `coin` for some ham
    public entry fun buy_ham(
        grocery: &mut Grocery,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let _balance = coin::into_balance(coin);
        assert!(balance::value(&_balance) == HAM_PRICE, EInsuffilientFunds);
        balance::join(&mut grocery.profits, _balance);
        transfer::transfer(Ham { id: object::new(ctx) }, tx_context::sender(ctx))
    }

    /// Exchange `coin` for some bread
    public entry fun buy_bread(
        grocery: &mut Grocery,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let _balance = coin::into_balance(coin);
        assert!(balance::value(&_balance) == BREAD_PRICE, EInsuffilientFunds);
        balance::join(&mut grocery.profits, _balance);
        transfer::transfer(Bread { id: object::new(ctx) }, tx_context::sender(ctx))
    }

    /// Combine the `ham` and `bread` into a delicious sandwich
    public entry fun make_sandwich(
        ham: Ham, bread: Bread, ctx: &mut TxContext
    ) {
        let Ham { id: ham_id } = ham;
        let Bread { id: bread_id } = bread;
        object::delete(ham_id);
        object::delete(bread_id);
        transfer::transfer(Sandwich { id: object::new(ctx) }, tx_context::sender(ctx))
    }

    /// See the profits of a grocery
    public fun profits(grocery: &Grocery): u64 {
        balance::value(&grocery.profits)
    }

    /// Owner of the grocery can collect profits by passing his capability
    public entry fun collect_profits(_cap: &GroceryOwnerCapability, grocery: &mut Grocery, ctx: &mut TxContext) {
        let amount = profits(grocery);
        assert!(amount > 0, ENoProfits);

        // Take a transferable `Coin` from a `Balance`
        let coin = coin::take(&mut grocery.profits, amount, ctx);

        transfer::transfer(coin, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
