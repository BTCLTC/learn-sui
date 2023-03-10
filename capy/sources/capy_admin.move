module basics::capy_admin {
    use capy::capy::{Self, CapyManagerCap, CapyRegistry, Capy};
    use sui::tx_context::TxContext;

    entry fun add_gene(
        cap: &CapyManagerCap,
        reg: &mut CapyRegistry,
        name: vector<u8>,
        definitions: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        capy::add_gene(cap, reg, name, definitions, ctx);
    }

    entry fun batch_sell_capys(
        cap: &CapyManagerCap,
        reg: &mut CapyRegistry,
        market: &mut CapyMarket<Capy>,
        genes: vector<vector<u8>>,
        price: u64,
        ctx: &mut TxContext
    ) {
        let capys = capy::batch(cap, reg, genes, ctx);
        capy_market::batch_list(market, genes, price, ctx);
    }
}
