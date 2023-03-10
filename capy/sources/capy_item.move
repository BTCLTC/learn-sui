module basics::capy_item {
    use sui::balance::Balance;
    use std::string::{Self, String};
    use sui::sui::SUI;
    use sui::object::{UID, ID};
    use sui::url::Url;
    use std::option::Option;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::object;
    use sui::balance;
    use sui::tx_context;
    use sui::coin;
    use sui::dynamic_object_field;
    use std::option;
    use sui::coin::Coin;
    use std::vector as vec;
    use sui::event::emit;
    use sui::pay;
    use sui::url;

    /// Base path for `CapyItem.url` attribute. Is temporary and improves
    /// explorer / wallet display. Always points to the dev/testnet server.
    const IMAGE_URL: vector<u8> = b"https://api.capy.art/items/";

    /// Store for any type T. Collects profits from all sold listings
    /// to be later acquirable by the Capy Admin.
    struct ItemStore has key {
        id: UID,
        balance: Balance<SUI>
    }

    /// A Capy item, that is being purchased from the `ItemStore`.
    struct CapyItem has key, store {
        id: UID,
        name: String,
        /// Urls and other meta information should
        /// always go last as it allows for partial
        /// deserialization of data on the frontend
        url: Url,
    }

    /// A Capability granting the bearer full control over the `ItemStore`.
    struct StoreOwnerCap has key, store {
        id: UID
    }

    /// A listing for an Item. Supply is either finite or infinite.
    struct ListedItem has key, store {
        id: UID,
        url: Url,
        name: String,
        type: String,
        price: u64,
        quantity: Option<u64>
    }

    // ============ Events ===============

    /// Emitted when new item is purchased.
    /// Off-chain we only need to know which ID
    /// corresponds to which name to serve the data.
    struct ItemCreatedEvent has copy, drop {
        id: ID,
        name: String,
    }

    // ============ Functions ===============

    /// Create a `itemStore` and a `StoreOwnerCap` for this store.
    fun init(ctx: &mut TxContext) {
        transfer::share_object(ItemStore {
            id: object::new(ctx),
            balance: balance::zero()
        });

        transfer::transfer(StoreOwnerCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx))
    }

    /// Admin action - collect Profits from the `ItemStore`
    public entry fun collect_profits(
        s: &mut ItemStore, ctx: &mut TxContext
    ) {
        let a = balance::value(&s.balance);
        let b = balance::split(&mut s.balance, a);

        transfer::transfer(coin::from_balance(b, ctx), tx_context::sender(ctx))
    }

    /// Change the quantity value for the listing in the `ItemStore`.
    public entry fun set_quantity(
        s: &mut ItemStore,
        name: vector<u8>,
        quantity: u64
    ) {
        let listing = dynamic_object_field::borrow_mut<vector<u8>, ListedItem>(&mut s.id, name);
        option::swap(&mut listing.quantity, quantity);
    }

    /// List an item in the `ItemStore` to be freely purchasable
    /// within the set quantity (if set).
    public entry fun sell(
        s: &mut ItemStore,
        name: vector<u8>,
        type: vector<u8>,
        price: u64,
        ctx: &mut TxContext
    ) {
        dynamic_object_field::add(
            &mut s.id,
            name,
            ListedItem {
                id: object::new(ctx),
                url: img_url(name),
                price,
                quantity: option::none(),
                name: string::utf8(name),
                type: string::utf8(type)
            }
        );
    }

    /// Buy an Item from the `ItemStore`. Pay `Coin<SUI>` and
    /// receive a `CapyItem`.
    public entry fun buy_and_take(
        s: &mut ItemStore,
        name: vector<u8>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let listing = dynamic_object_field::borrow_mut<vector<u8>, ListedItem>(&mut s.id, name);

        // check that the Coin amount matches the price; then add it to the balance
        assert!(coin::value(&payment) == listing.price, 0);
        coin::put(&mut s.balance, payment);

        // if quantity is set, make sure that it's not 0; then decrement
        if (option::is_some(&listing.quantity)) {
            let q = option::borrow(&listing.quantity);
            assert!(*q > 0, 1);
            option::swap(&mut listing.quantity, *q - 1);
        };

        let id = object::new(ctx);

        emit(ItemCreatedEvent {
            id: object::uid_to_inner(&id),
            name: listing.name
        });

        transfer::transfer(CapyItem {
            id,
            url: listing.url,
            name: listing.name
        }, tx_context::sender(ctx))
    }

    /// Buy a Capy Item with a single Coin which may be bigger than the
    /// price of the listing.
    public entry fun buy_mut(
        s: &mut ItemStore,
        name: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let listing = dynamic_object_field::borrow<vector<u8>, ListedItem>(&mut s.id, name);
        let paid = coin::split(payment, listing.price, ctx);
        buy_and_take(s, name, paid, ctx)
    }

    /// Buy a CapyItem with multiple Coins by joining them first and then
    /// calling the `buy_mut` function.
    public entry fun buy_mut_coin(
        s: &mut ItemStore,
        name: vector<u8>,
        coins: vector<Coin<SUI>>,
        ctx: &mut TxContext
    ) {
        let paid = vec::pop_back(&mut coins);
        pay::join_vec(&mut paid, coins);
        buy_mut(s, name, &mut paid, ctx);
        transfer::transfer(paid, tx_context::sender(ctx))
    }

    /// Construct an image URL for the `CapyItem`
    fun img_url(name: vector<u8>): Url {
        let capy_url = IMAGE_URL;
        vec::append(&mut capy_url, name);
        vec::append(&mut capy_url, b"/svg");

        url::new_unsafe_from_bytes(capy_url)
    }
}
