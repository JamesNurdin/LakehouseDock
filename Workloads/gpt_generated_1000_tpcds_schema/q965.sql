WITH
    sampled_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    ),
    agg_returns AS (
        SELECT
            sr_store_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_refunded_cash) AS total_refunded_cash,
            COUNT(*) AS cnt_returns,
            AVG(sr_return_quantity) AS avg_return_qty,
            CASE WHEN SUM(sr_net_loss) > 5000 THEN 1 ELSE 0 END AS high_net_loss_flag
        FROM sampled_returns
        WHERE sr_refunded_cash > 100      -- selective predicate
          AND sr_store_credit < 30        -- selective predicate
        GROUP BY sr_store_sk
    ),
    store_ca AS (
        SELECT
            s_store_sk,
            s_store_id,
            s_state,
            s_city,
            s_floor_space,
            s_rec_start_date,
            s_rec_end_date,
            s_market_id
        FROM store
        WHERE s_state = 'CA'
          AND s_floor_space > 2000
          AND s_rec_start_date >= DATE '1999-01-01'
          AND s_rec_end_date   <= DATE '2001-12-31'
    ),
    store_ny AS (
        SELECT
            s_store_sk,
            s_store_id,
            s_state,
            s_city,
            s_floor_space,
            s_rec_start_date,
            s_rec_end_date,
            s_market_id
        FROM store
        WHERE s_state = 'NY'
          AND s_floor_space > 2000
          AND s_rec_start_date >= DATE '1999-01-01'
          AND s_rec_end_date   <= DATE '2001-12-31'
    ),
    union_stores AS (
        SELECT DISTINCT s_store_sk, s_store_id, s_state, s_city, s_floor_space, s_rec_start_date, s_rec_end_date, s_market_id
        FROM store_ca
        UNION DISTINCT
        SELECT DISTINCT s_store_sk, s_store_id, s_state, s_city, s_floor_space, s_rec_start_date, s_rec_end_date, s_market_id
        FROM store_ny
    ),
    excluded_keys AS (
        SELECT s_store_sk
        FROM store
        WHERE s_state = 'CA'
        EXCEPT
        SELECT s_store_sk
        FROM store
        WHERE s_city = 'Los Angeles'
    )
SELECT
    u.s_store_id,
    u.s_state,
    u.s_city,
    ar.total_return_amt,
    ar.total_refunded_cash,
    ar.cnt_returns,
    ar.avg_return_qty,
    CASE WHEN ar.high_net_loss_flag = 1 THEN 'HIGH' ELSE 'LOW' END AS net_loss_category
FROM union_stores u
JOIN agg_returns ar
    ON u.s_store_sk = ar.sr_store_sk
WHERE u.s_store_sk IN (SELECT s_store_sk FROM excluded_keys)
ORDER BY ar.total_return_amt DESC
LIMIT 100
