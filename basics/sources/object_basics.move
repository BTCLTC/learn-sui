module basics::object_basics {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::object;
    use sui::event;
    use sui::tx_context;

    struct Object has key, store {
        id: UID,
        value: u64,
    }

    struct Wrapper has key {
        id: UID,
        obj: Object
    }

    struct UpdateValueEvent has copy, drop {
        new_value: u64
    }

    public entry fun create(value: u64, recipient: address, ctx: &mut TxContext) {
        transfer::transfer(
            Object {
                id: object::new(ctx),
                value
            },
            recipient
        )
    }

    public entry fun transfer(obj: Object, recipient: address) {
        transfer::transfer(obj, recipient)
    }

    public entry fun freeze_object(obj: Object) {
        transfer::freeze_object(obj)
    }

    public entry fun set_value(obj: &mut Object, value: u64) {
        obj.value = value;
    }

    public entry fun update(obj1: &mut Object, obj2: &Object) {
        obj1.value = obj2.value;
        // emit an event so the world can see the new value
        event::emit(UpdateValueEvent { new_value: obj2.value })
    }

    public entry fun delete(obj: Object) {
        let Object { id, value: _ } = obj;
        object::delete(id);
    }

    public entry fun wrap(obj: Object, ctx: &mut TxContext) {
        transfer::transfer(Wrapper { id: object::new(ctx), obj }, tx_context::sender(ctx))
    }

    public entry fun unwrap(w: Wrapper, ctx: &mut TxContext) {
        let Wrapper { id, obj } = w;
        object::delete(id);
        transfer::transfer(obj, tx_context::sender(ctx))
    }
}
