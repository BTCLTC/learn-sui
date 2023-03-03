#[test_only]
module basics::lock_tests {
    use basics::lock::{Self, Lock, Key};
    use sui::object::{Self, UID};
    use sui::test_scenario;
    use sui::transfer;

    /// Custom structure which we will store inside a Lock.
    struct Treasure has store, key {
        id: UID
    }

    #[test]
    fun test_lock() {
        let user1 = @0x1;
        let user2 = @0x2;

        let scenario_val = test_scenario::begin(user1);
        let scenario = &mut scenario_val;

        // User1 creates a lock and places his treasure inside.
        test_scenario::next_tx(scenario, user1);
        {
            let ctx = test_scenario::ctx(scenario);
            let id = object::new(ctx);

            lock::create(Treasure { id }, ctx);
        };

        // Now User1 owns a key from the lock. He decides to send this
        // key to User2, so that he can have access to the stored treasure.
        test_scenario::next_tx(scenario, user1);
        {
            let key = test_scenario::take_from_sender<Key<Treasure>>(scenario);

            transfer::transfer(key, user2);
        };

        // User2 is impatient and he decides to take the treasure.
        test_scenario::next_tx(scenario, user2);
        {
            let lock_val = test_scenario::take_shared<Lock<Treasure>>(scenario);
            let lock = &mut lock_val;
            let key = test_scenario::take_from_sender<Key<Treasure>>(scenario);
            let ctx = test_scenario::ctx(scenario);

            lock::take<Treasure>(lock, &key, ctx);

            test_scenario::return_shared(lock_val);
            test_scenario::return_to_sender(scenario, key);
        };
        test_scenario::end(scenario_val);
    }
}
