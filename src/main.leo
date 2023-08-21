program arcane_ammswap_000003.aleo {

    mapping tokens: field => TokenInfo;
    mapping balances: field => u128;

    mapping user_balance_keys: address => UserBalanceKeys; 

    struct UserBalanceKeys {
        key0: field;
        key1: field;
        key2: field;
        key3: field;
        key4: field;
        key5: field;
        key6: field;
        key7: field;
        key8: field;
        key9: field;
    }
    
    mapping pools: field => Pool;
    
    mapping m_access: bool => AccessInfo;
    mapping m_token_index: bool  => TokenIndex;
    mapping m_fee: bool => Fee;

    struct Fee {
        fee: u128, // 10000 based, 1 means 0.01% 
    }

    struct AccessInfo {
        admin: address,
    }

    struct TokenIndex {
        index: field,
    }

    // no tokens are minted upon token creation
    // admin can mint any amount of tokens up to total_supply
    // other people can mint any amount up to total_supply but individual mint can't be larger than faucets[token_index].max_amount
    struct TokenInfo {
        name: field,
        symbol: field,
        decimals: u8,
        circulating_supply: u128,
        total_supply: u128,
        admin: address,
        faucet_info: FaucetInfo
    }

    struct FaucetInfo {
        enabled: bool,
        max_amount: u128,
    }

    struct Pool {
        reserve0: u128,
        reserve1: u128,
    }

    struct Key {
        field1: field,
        field2: field,
    }

    transition init(public dummy: u8) {
        return then finalize(self.caller);
    }

    finalize init(public admin: address) {
        // call init only once
        assert(!Mapping::contains(m_access, true));
        Mapping::set(m_access, true, AccessInfo {
            admin: admin,
        });
        Mapping::set(m_token_index, true, TokenIndex {
            index: 0field,
        });
        Mapping::set(m_fee, true, Fee {
            fee: 30u128,
        });
    }

    transition set_fee(public value: u128) {
        assert(value <= 10000u128);
        return then finalize(self.caller, value);
    }

    finalize set_fee(public caller: address, public value: u128) {
        let access: AccessInfo = Mapping::get(m_access, true);
        assert_eq(access.admin, caller);
        Mapping::set(m_fee, true, Fee {
            fee: value,
        });
    }

    transition create_token(public info: TokenInfo) -> field {
        assert(info.circulating_supply == 0u128);
        return then finalize(info, self.caller);
    }

    finalize create_token(public info: TokenInfo, public caller: address) {
        let token_index: TokenIndex = Mapping::get(m_token_index, true);
        let new_index: field = token_index.index + 1field;
        Mapping::set(m_token_index, true, TokenIndex {
            index: new_index,
        });
        
        Mapping::set(tokens, token_index.index, info);
    }

    // Transfer public tokens.
    transition transfer(public token_index: field, public to: address, public amount: u128) {
        return then finalize(token_index, self.caller, to, amount);
    }

    finalize transfer(public token_index: field, public from: address, public to: address, public amount: u128) {
        assert(Mapping::contains(tokens, token_index));
        
        let from_balance_key: field = get_balance_key(token_index, from);
        let from_initial_balance: u128 = Mapping::get(balances, from_balance_key);
        Mapping::set(balances, from_balance_key, from_initial_balance - amount);
        
        let to_balance_key: field = get_balance_key(token_index, to);
        let to_initial_balance: u128 = Mapping::get(balances, to_balance_key);
        Mapping::set(balances, to_balance_key, to_initial_balance + amount);
    }

    transition update_token_faucet(public token_index: field, public faucet: FaucetInfo) {
        return then finalize(self.caller, token_index, faucet);
    }

    finalize update_token_faucet(public caller: address, public token_index: field, public faucet: FaucetInfo) {
        let token_info: TokenInfo = Mapping::get(tokens, token_index);
        assert_eq(caller, token_info.admin);
        Mapping::set(tokens, token_index, TokenInfo {
            name: token_info.name,
            symbol: token_info.symbol,
            decimals: token_info.decimals,
            circulating_supply: token_info.circulating_supply,
            total_supply: token_info.total_supply,
            admin: token_info.admin,
            faucet_info: faucet
        });
    }

    transition mint_public(public token_index: field, public to: address, public amount: u128) {
        return then finalize(token_index, self.caller, to, amount);
    }

    finalize mint_public(public token_index: field, public caller: address, public to: address, amount: u128) {
        let token_info: TokenInfo = Mapping::get(tokens, token_index);
        if (caller != token_info.admin) {
            assert(token_info.faucet_info.enabled);
            assert(amount > 0u128 && amount <= token_info.faucet_info.max_amount);
        }
        let circulating_supply: u128 = token_info.circulating_supply + amount;
        assert(circulating_supply <= token_info.total_supply);

        Mapping::set(tokens, token_index, TokenInfo {
            name: token_info.name,
            symbol: token_info.symbol,
            decimals: token_info.decimals,
            circulating_supply: circulating_supply,
            total_supply: token_info.total_supply,
            admin: token_info.admin,
            faucet_info: token_info.faucet_info
        });
        let balance_keys: UserBalanceKeys = Mapping::get_or_use(user_balance_keys, caller, UserBalanceKeys {
            key0: 0field,
            key1: 0field,
            key2: 0field,
            key3: 0field,
            key4: 0field,
            key5: 0field,
            key6: 0field,
            key7: 0field,
            key8: 0field,
            key9: 0field,
        });

        let balance_key: field = get_balance_key(token_index, caller);
        // temporary solution to help frontend with fetching balances
        Mapping::set(user_balance_keys, caller, UserBalanceKeys {
            key0: token_index == 0field ? balance_key : balance_keys.key0, 
            key1: token_index == 1field ? balance_key : balance_keys.key1,
            key2: token_index == 2field ? balance_key : balance_keys.key2,
            key3: token_index == 3field ? balance_key : balance_keys.key3,
            key4: token_index == 4field ? balance_key : balance_keys.key4,
            key5: token_index == 5field ? balance_key : balance_keys.key5,
            key6: token_index == 6field ? balance_key : balance_keys.key6,
            key7: token_index == 7field ? balance_key : balance_keys.key7,
            key8: token_index == 8field ? balance_key : balance_keys.key8,
            key9: token_index == 9field ? balance_key : balance_keys.key9,
        });
        let bal: u128 = Mapping::get_or_use(balances, balance_key, 0u128);
        Mapping::set(balances, balance_key, bal + amount);
    }

    transition change_admin(public admin: address) {
        return then finalize(self.caller, admin);
    }

    finalize change_admin(public caller: address, public admin: address) {
        let access_info: AccessInfo = Mapping::get(m_access, true);
        assert_eq(caller, access_info.admin);
        Mapping::set(m_access, true, AccessInfo {
            admin: admin,
        });
    }

    // ========================= liquidity =========================
    transition create_pool(
        public token0: field,
        public token1: field,
        public amount0: u128,
        public amount1: u128,
        public to: address
     ) {
        return then finalize(self.caller, token0, token1, amount0, amount1, to);
    }

    finalize create_pool(
        public caller: address,
        public token0: field,
        public token1: field,
        public amount0: u128,
        public amount1: u128,
        public to: address
    ) {
        let pool_key: field = get_pool_key(token0, token1);
        let liquidity: u128 = sqrt_u128(amount0 * amount1);
        assert(liquidity > 0u128);

        let lp_token_info: TokenInfo = Mapping::get_or_use(tokens, pool_key, TokenInfo {
            name: 0field, 
            symbol: 0field,
            decimals: 18u8,
            circulating_supply: 0u128,
            total_supply: 0u128,
            admin: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
            faucet_info: FaucetInfo {
                enabled: false,
                max_amount: 0u128,
            },
        });

        let pool: Pool = Mapping::get_or_use(pools, pool_key, Pool {
            reserve0: 0u128,
            reserve1: 0u128,
        });


        let token0_balance_key: field = get_balance_key(token0, caller);
        Mapping::set(balances, token0_balance_key, Mapping::get(balances, token0_balance_key) - amount0);
        let token1_balance_key: field = get_balance_key(token1, caller);
        Mapping::set(balances, token1_balance_key, Mapping::get(balances, token1_balance_key) - amount1);

        // mint liquidity
        let bid_p: field = get_balance_key(pool_key, to);
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity);
        Mapping::set(tokens, pool_key, TokenInfo {
            name: lp_token_info.name,
            symbol: lp_token_info.symbol,
            decimals: lp_token_info.decimals,
            circulating_supply: lp_token_info.circulating_supply,
            total_supply: lp_token_info.total_supply + liquidity,
            admin: lp_token_info.admin,
            faucet_info: FaucetInfo {
                enabled: false, max_amount: 0u128
            }
        });

        // update pool
        Mapping::set(pools, pool_key, Pool {
            reserve0: pool.reserve0 + amount0,
            reserve1: pool.reserve1 + amount1,
        });
    }

    transition add_liquidity(
        public token0: field,
        public token1: field,
        public amount0: u128,
        public amount1: u128,
        public min0: u128,
        public min1: u128,
        public to: address
     ) {
        assert(token0 < token1);
        assert(amount0 > 0u128 && amount0 >= min0);
        assert(amount1 > 0u128 && amount1 >= min1);
        return then finalize(self.caller, token0, token1, amount0, amount1, min0, min1, to);
    }

    finalize add_liquidity(
        public caller: address,
        public token0: field,
        public token1: field,
        public amount0: u128,
        public amount1: u128,
        public min0: u128,
        public min1: u128,
        public to: address
    ) {
        let pool_key: field = get_pool_key(token0, token1);
        let pool: Pool = Mapping::get(pools, pool_key);
        let lp_token_info: TokenInfo = Mapping::get(tokens, pool_key);
        let liquidity0: u128 = amount0 * lp_token_info.total_supply / pool.reserve0;
        let liquidity1: u128 = amount1 * lp_token_info.total_supply / pool.reserve1;
        let liquidity: u128 = liquidity0 <= liquidity1 ? liquidity0 : liquidity1;
        amount0 = liquidity0 <= liquidity
                ? amount0
                : (liquidity * pool.reserve0 + lp_token_info.total_supply - 1u128) / lp_token_info.total_supply;
        amount1 = liquidity1 <= liquidity
                ? amount1
                : (liquidity * pool.reserve1 + lp_token_info.total_supply - 1u128) / lp_token_info.total_supply;
        assert(liquidity > 0u128);
        assert(amount0 >= min0);
        assert(amount1 >= min1);

        // update balances
        let token0_balance_key: field = get_balance_key(token0, caller);
        Mapping::set(balances, token0_balance_key, Mapping::get(balances, token0_balance_key) - amount0);
        let token1_balance_key: field = get_balance_key(token1, caller);
        Mapping::set(balances, token1_balance_key, Mapping::get(balances, token1_balance_key) - amount1);

        // mint liquidity
        let bid_p: field = get_balance_key(pool_key, to);
        Mapping::set(balances, bid_p, Mapping::get_or_use(balances, bid_p, 0u128) + liquidity);
        Mapping::set(tokens, pool_key, TokenInfo {
            name: lp_token_info.name,
            symbol: lp_token_info.symbol,
            decimals: lp_token_info.decimals,
            circulating_supply: lp_token_info.circulating_supply,
            total_supply: lp_token_info.total_supply + liquidity,
            admin: lp_token_info.admin,
            faucet_info: lp_token_info.faucet_info
        });

        // update pool
        Mapping::set(pools, pool_key, Pool {
            reserve0: pool.reserve0 + amount0,
            reserve1: pool.reserve1 + amount1,
        });
    }

    // Remove liquidity from a pool.
    // The caller's LP tokens will be burned, `token0` and `token1` will be transferred to the `to` address.
    transition remove_liquidity(
        public token0: field,
        public token1: field,
        public liquidity: u128,
        public min0: u128,
        public min1: u128,
        public to: address,
     ) {
        assert(token0 < token1);
        assert(liquidity > 0u128);
        return then finalize(self.caller, token0, token1, liquidity, min0, min1, to);
    }

    finalize remove_liquidity(
        public caller: address,
        public token0: field,
        public token1: field,
        public liquidity: u128,
        public min0: u128,
        public min1: u128,
        public to: address,
    ) {
        let pool_key: field = get_pool_key(token0, token1);
        let lp_token_info: TokenInfo = Mapping::get(tokens, pool_key);
        let pool: Pool = Mapping::get(pools, pool_key);

        // calculate token amounts
        let amount0: u128 = liquidity * pool.reserve0 / lp_token_info.total_supply;
        let amount1: u128 = liquidity * pool.reserve1 / lp_token_info.total_supply;
        assert(amount0 >= min0 && amount1 >= min1);
        assert(amount0 > 0u128 || amount1 > 0u128);

        // burn liquidity
        let bid_p: field = get_balance_key(pool_key, caller);
        Mapping::set(balances, bid_p, Mapping::get(balances, bid_p) - liquidity);
        Mapping::set(tokens, pool_key, TokenInfo {
            name: lp_token_info.name,
            symbol: lp_token_info.symbol,
            decimals: lp_token_info.decimals,
            circulating_supply: lp_token_info.circulating_supply,
            total_supply: lp_token_info.total_supply - liquidity,
            admin: lp_token_info.admin,
            faucet_info: lp_token_info.faucet_info
        });

        // update pool
        Mapping::set(pools, pool_key, Pool {
            reserve0: pool.reserve0 - amount0,
            reserve1: pool.reserve1 - amount1,
        });

        // send tokens
        let token0_balance_key: field = get_balance_key(token0, to);
        let token1_balance_key: field = get_balance_key(token1, to);
        Mapping::set(balances, token0_balance_key, Mapping::get_or_use(balances, token0_balance_key, 0u128) + amount0);
        Mapping::set(balances, token1_balance_key, Mapping::get_or_use(balances, token1_balance_key, 0u128) + amount1);
    }

    transition swap_exact_tokens_for_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
     ) {
        assert(token_in != token_out);
        assert(amount_in > 0u128);
        return then finalize(self.caller, token_in, token_out, amount_in, amount_out_min, to);
    }

    finalize swap_exact_tokens_for_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in: u128,
        public amount_out_min: u128,
        public to: address,
    ) {
        let token0: field = token_in < token_out ? token_in : token_out;
        let token1: field = token_in < token_out ? token_out : token_in;
        let pool_key: field = get_pool_key(token0, token1);
        let pool: Pool = Mapping::get(pools, pool_key);

        let reserve_in: u128 = token0 == token_in ? pool.reserve0 : pool.reserve1;
        let reserve_out: u128 = token0 == token_out ? pool.reserve0 : pool.reserve1;
        let fee: Fee = Mapping::get(m_fee, true);
        let amount_in_with_fee: u128 = amount_in * (10000u128 - fee.fee);
        let amount_out: u128 = amount_in_with_fee * reserve_out / (reserve_in * 10000u128 + amount_in_with_fee);
        assert(amount_out >= amount_out_min);
        assert(amount_out > 0u128);

        // transfer input token
        let in_balance_key: field = get_balance_key(token_in, caller);
        Mapping::set(balances, in_balance_key, Mapping::get(balances, in_balance_key) - amount_in);

        // update pool
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pools, pool_key, Pool {
            reserve0: token0 == token_in ? reserve_in_new : reserve_out_new,
            reserve1: token1 == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        let out_balance_key: field = get_balance_key(token_out, to);
        Mapping::set(balances, out_balance_key, Mapping::get_or_use(balances, out_balance_key, 0u128) + amount_out);
    }

    // Exchange a variable amount of input token for a fixed amount of output token.
    transition swap_tokens_for_exact_tokens(
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
     ) {
        return then finalize(self.caller, token_in, token_out, amount_in_max, amount_out, to);
    }

    finalize swap_tokens_for_exact_tokens(
        public caller: address,
        public token_in: field,
        public token_out: field,
        public amount_in_max: u128,
        public amount_out: u128,
        public to: address,
    ) {
        let token0: field = token_in < token_out ? token_in : token_out;
        let token1: field = token_in < token_out ? token_out : token_in;
        let pool_key: field = get_pool_key(token_in, token_out);
        let pool: Pool = Mapping::get(pools, pool_key);

        // calculate input amount
        let reserve_in: u128 = token0 == token_in ? pool.reserve0 : pool.reserve1;
        let reserve_out: u128 = token0 == token_out ? pool.reserve0 : pool.reserve1;
        let fee: Fee = Mapping::get(m_fee, true);
        let amount_in: u128 = reserve_in * amount_out * 10000u128 / ((reserve_out - amount_out) * (10000u128 - fee.fee)) + 1u128;
        assert(amount_in <= amount_in_max);
        assert(amount_in > 0u128);

        // transfer input token
        let in_balance_key: field = get_balance_key(token_in, caller);
        Mapping::set(balances, in_balance_key, Mapping::get(balances, in_balance_key) - amount_in);

        // update pool
        let reserve_in_new: u128 = reserve_in + amount_in;
        let reserve_out_new: u128 = reserve_out - amount_out;
        Mapping::set(pools, pool_key, Pool {
            reserve0: token0 == token_in ? reserve_in_new : reserve_out_new,
            reserve1: token1 == token_in ? reserve_in_new : reserve_out_new,
        });

        // transfer output token
        let out_balance_key: field = get_balance_key(token_out, to);
        Mapping::set(balances, out_balance_key, Mapping::get_or_use(balances, out_balance_key, 0u128) + amount_out);
    }

    // utils
    inline get_balance_key(token: field, user: address) -> field {
        let field_user: field = user as field;
        let a_token: field = token;
        return BHP1024::hash_to_field(Key {field1: a_token, field2: field_user });
    }

    transition dummy_get_pool_key(a: field, b: field) -> field {
        return get_pool_key(a, b);       
    }

    inline get_pool_key(token0: field, token1: field) -> field {
        let actual_token0: field = token0 > token1 ? token1 : token0;
        let actual_token1: field = token0 <= token1 ? token1 : token0;
        return BHP1024::hash_to_field(Key {field1: actual_token0, field2: actual_token1});
    }

    inline min_u128(a: u128, b: u128) -> u128 {
        return a < b ? a : b;
    }

    inline sqrt_u128(a: u128) -> u128 {
        if (a == 0u128) {
            return 0u128;
        }
        let result: u128 = 1u128.shl(log2(a) / 2u32);

        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        result = (result + a / result) >> 1u32;
        return min_u128(result, a / result);
    }

    // log2 for u128
    inline log2(value: u128) -> u32 {
        let result: u32 = 0u32;
        if value >> 64u32 > 0u128 {
            value >>= 64u32;
            result += 64u32;
        }
        if value >> 32u32 > 0u128 {
            value >>= 32u32;
            result += 32u32;
        }
        if value >> 16u32 > 0u128 {
            value >>= 16u32;
            result += 16u32;
        }
        if value >> 8u32 > 0u128 {
            value >>= 8u32;
            result += 8u32;
        }
        if value >> 4u32 > 0u128 {
            value >>= 4u32;
            result += 4u32;
        }
        if value >> 2u32 > 0u128 {
            value >>= 2u32;
            result += 2u32;
        }
        if value >> 1u32 > 0u128 {
            result += 1u32;
        }
        return result;
    }

}