#[test_only]
module fungible_tokens::private_coin_tests {
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use fungible_tokens::private_coin::{Self as pc};
    use fungible_tokens::private_balance::{Self as pb};
    use sui::transfer;
    use sui::elliptic_curve::{Self as ec};
    use std::option;

    /// Gonna be our test token.
    struct MIZU has drop {}

    // Tests section
    #[test] fun test_init_pool() {
        let scenario = scenario();
        test_transfer_private_coin(&mut scenario);
        test::end(scenario);
    }

    fun test_transfer_private_coin(scenario: &mut Scenario) {
        let (owner, recipient) = people();

        // Create currency
        next_tx(scenario, owner);
        {
            let cap = pc::create_currency(MIZU {}, ctx(scenario));
            transfer::transfer(cap, owner);
        };

        // Mint private coin
        next_tx(scenario, owner); {
            let cap = test::take_from_sender<pc::TreasuryCap<MIZU>>(scenario);
            pc::mint_and_transfer(
                &mut cap,
                1000,
                recipient,
                ctx(scenario)
            );
            test::return_to_sender(scenario, cap);
        };

        // Split and transfer private coin
        next_tx(scenario, recipient); {
            let coin = test::take_from_sender<pc::PrivateCoin<MIZU>>(scenario);
            // This should be created off-chain in the actual implementation
            let commit = ec::create_pedersen_commitment(
                ec::new_scalar_from_u64(990u64),
                ec::new_scalar_from_u64(10u64),
            );

            // Prove that the commitment of value = 10 = 1000 - 990,
            // with binding factor = (0 - 10) mod P = vector[227, 211, 245, 92, 26, 99, 18, 88, 214, 156, 247, 162, 222,
            // 249, 222, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];
            // is within range [0, 2^64)
            let proof = vector[48, 84, 247, 109, 130, 45, 229, 225, 6, 75, 254, 40, 35, 116, 150, 71, 124, 182, 147,
            145, 177, 1, 249, 21, 187, 131, 147, 182, 91, 95, 36, 43, 178, 233, 157, 83, 124, 76, 58, 150, 28, 149, 84,
            147, 157, 173, 214, 222, 107, 80, 149, 83, 183, 79, 151, 78, 174, 235, 212, 76, 223, 168, 240, 47, 206, 254,
            216, 226, 85, 79, 109, 4, 165, 181, 130, 48, 85, 147, 59, 131, 47, 248, 214, 29, 118, 50, 174, 215, 166,
            142, 130, 191, 229, 134, 37, 53, 202, 204, 50, 83, 13, 11, 180, 138, 99, 20, 52, 69, 117, 49, 156, 231, 32,
            45, 166, 205, 252, 218, 3, 50, 103, 123, 176, 22, 171, 30, 131, 28, 128, 42, 149, 37, 226, 12, 103, 165,
            252, 210, 137, 133, 86, 61, 9, 9, 44, 9, 125, 107, 185, 225, 106, 190, 175, 170, 38, 203, 187, 12, 190, 1,
            19, 180, 120, 122, 148, 161, 127, 175, 46, 201, 19, 180, 1, 27, 192, 52, 25, 144, 49, 112, 62, 234, 86, 22,
            155, 201, 204, 49, 179, 149, 69, 3, 12, 88, 158, 11, 72, 58, 12, 236, 17, 12, 79, 214, 146, 157, 49, 211,
            202, 139, 175, 244, 7, 232, 182, 172, 184, 59, 61, 82, 162, 157, 216, 13, 198, 160, 186, 100, 27, 127, 184,
            178, 185, 181, 188, 84, 61, 104, 16, 140, 50, 138, 245, 163, 177, 202, 181, 25, 190, 161, 185, 103, 245,
            215, 170, 23, 60, 142, 201, 212, 246, 237, 218, 70, 74, 146, 175, 119, 178, 19, 189, 46, 133, 148, 39, 172,
            156, 38, 47, 10, 182, 140, 94, 251, 212, 104, 46, 82, 98, 113, 61, 140, 33, 26, 161, 171, 193, 178, 17, 219,
            19, 222, 134, 17, 198, 64, 105, 197, 163, 153, 110, 167, 248, 138, 202, 233, 247, 175, 208, 35, 240, 222,
            126, 30, 198, 82, 74, 85, 200, 145, 148, 224, 77, 217, 116, 146, 41, 251, 142, 228, 3, 136, 86, 180, 157,
            102, 15, 81, 176, 42, 228, 39, 104, 92, 98, 42, 200, 31, 111, 242, 235, 233, 42, 175, 117, 226, 139, 187,
            180, 75, 96, 23, 107, 54, 95, 190, 196, 187, 134, 75, 86, 68, 169, 30, 34, 58, 132, 22, 73, 76, 19, 167,
            246, 229, 50, 0, 34, 3, 129, 156, 192, 119, 95, 206, 71, 204, 174, 75, 57, 9, 224, 123, 147, 132, 214, 68,
            30, 24, 5, 92, 36, 199, 177, 181, 77, 104, 103, 218, 128, 252, 102, 219, 195, 221, 251, 171, 171, 123, 229,
            111, 190, 91, 83, 81, 113, 87, 255, 31, 136, 68, 58, 76, 105, 0, 215, 118, 18, 201, 178, 49, 160, 58, 255,
            124, 155, 253, 68, 177, 242, 36, 48, 104, 190, 218, 233, 42, 34, 45, 247, 92, 40, 8, 238, 163, 33, 42, 157,
            211, 88, 244, 42, 221, 11, 242, 186, 1, 62, 65, 205, 119, 73, 116, 196, 94, 111, 45, 164, 136, 149, 12, 64,
            3, 228, 129, 252, 182, 132, 97, 36, 217, 52, 146, 137, 80, 13, 3, 78, 114, 124, 44, 169, 73, 193, 171, 59,
            220, 61, 59, 41, 67, 87, 147, 28, 95, 166, 188, 116, 49, 182, 56, 85, 51, 132, 75, 252, 45, 135, 175, 68,
            166, 198, 28, 250, 125, 251, 27, 197, 140, 222, 95, 51, 133, 149, 189, 2, 16, 164, 128, 111, 222, 85, 88,
            59, 173, 129, 44, 152, 158, 218, 166, 138, 187, 103, 142, 39, 112, 172, 80, 77, 150, 104, 234, 39, 124, 169,
            144, 188, 126, 180, 11, 205, 227, 213, 34, 0, 130, 248, 223, 39, 137, 246, 113, 113, 148, 199, 13, 215, 212,
            121, 10, 7, 49, 3, 242, 122, 190, 44, 171, 193, 9, 163, 24, 247, 108, 214, 55, 252, 51, 47, 167, 233, 69,
            42, 42, 102, 161, 252, 84, 240, 89, 68, 185, 125, 127, 252, 121, 255, 173, 100, 240, 89, 15];

            pc::split_and_transfer<MIZU>(
                &mut coin,
                ec::bytes(&commit),
                proof,
                owner,
                ctx(scenario)
            );

            test::return_to_sender(scenario, coin);
        };

        // Check that balances are correct when opened
        next_tx(scenario, recipient); {
            let coin = test::take_from_sender<pc::PrivateCoin<MIZU>>(scenario);
            let value = 10u64;
            // (0 - 10) mod P
            let blinding = vector[227, 211, 245, 92, 26, 99, 18, 88, 214, 156, 247, 162, 222, 249, 222, 20, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];
            // Open the coin
            pc::open_coin(&mut coin, value, blinding);
            // Get the opened public balance and check that this is accurate
            assert!(*option::borrow(&pb::value(pc::balance(&coin))) == value, 0);
            test::return_to_sender(scenario, coin);
        };

        // Transfer a public coin out. Ensure that this still remains public
        next_tx(scenario, recipient); {
            let coin = test::take_from_sender<pc::PrivateCoin<MIZU>>(scenario);
            let value = 1u64;
            // Open the coin
            pc::split_public_and_transfer<MIZU>(
                &mut coin,
                value,
                vector[],
                owner,
                ctx(scenario)
            );
            // Check that the coin is still public and equals to 9
            assert!(*option::borrow(&pb::value(pc::balance(&coin))) == 9, 0);
            test::return_to_sender(scenario, coin);
        };
    }
    // utilities
    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address) { (@0xB0BA, @0x7EA) }
}
