module basics::capy_market {
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;
    use capy::capy::Capy;
    use sui::object;
    use sui::event::emit;
    use sui::transfer;

    use std::vector as vec;

    /// For when someone tries to delist without ownership.
    const ENotOwner: u64 = 0;

    /// For when amoutn paid does not match the expected.
    const EAmountIncorrect: u64 = 1;

    /// For when there's nothing to claim from the marketplace.
    const ENoProfits: u64 = 2;

    // ========== Types ===========

    /// A generic marketplace for anything
    struct CapyMarket<phantom T> has key {
        id: UID,
    }

    /// A listing for the marketplace. Intermediary object which owns an item.
    struct Listing has key, store {
        id: UID,
        price: u64,
        owner: address
    }

    // ======== Events ========

    /// Emitted when a new CapyMarket is created.
    struct MarketCreated<phantom T> has copy, drop {
        market_id: ID,
    }

    /// Emitted when someone lists a new item on the CapyMarket<T>.
    struct ItemListed<phantom T> has copy, drop {
        listing_id: ID,
        item_id: ID,
        price: u64,
        owner: address
    }

    /// Emitted when owner delists an item from the CapyMarket<T>.
    struct ItemDelisted<phantom T> has copy, drop {
        listing_id: ID,
        item_id: ID,
    }

    /// Emitted when someone makes a purchase. `new_owner` shows
    /// who's a happy new owner of the purchased item.
    struct ItemPurchased<phantom T> has copy, drop {
        listing_id: ID,
        item_id: ID,
        new_owner: address
    }

    /// For when someone collects profits from the market. Helps
    /// indexer show who has how much.
    struct ProfitsCollected<phantom T> has copy, drop {
        owner: address,
        amount: u64,
    }

    // ========= Functions =========

    /// By default create two Markets
    fun init(ctx: &mut TxContext) {
        publish<Capy>(ctx);
    }

    /// Admin-only method which allows creating a new marketplace.
    public entry fun create_marketplace<T: key + store>(ctx: &mut TxContext) {
        publish<T>(ctx)
    }

    /// Publish a new CapyMarket for any type T. Method is private and
    /// can only be called in a module initializer or in an admin-only
    /// method `create_marketplace`
    fun publish<T: key + store>(ctx: &mut TxContext) {
        let id = object::new(ctx);
        emit(MarketCreated<T> {
            market_id: object::uid_to_inner(&id)
        });
        transfer::share_object(CapyMarket<T> { id });
    }

    // ========= CapyMarket Actions =========

    /// List a batch of T at once.
    public fun batch_list<T: key + store>(
        market: &mut CapyMarket<T>,
        items: vector<T>,
        price: u64,
        ctx: &mut TxContext
    ) {
        while (vec::length(&items) > 0) {
            list(market, vec::pop_back(&mut items), price, ctx)
        };

        vec::destroy_empty(items);
    }
}
