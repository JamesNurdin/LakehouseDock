/*
Goal: Identify the top performing stores in California by net profit after accounting for returns, using multiple layers of aggregation, filtering, a distinct‑store CTE, a scalar subquery with DISTINCT, and window functions.
*/
WITH distinct_stores AS (
    SELECT DISTINCT
        s.s_store_id,
        s.s_store_sk,
        s.s_city,
        s.s_state,
        s.s_number_employees,
        s.s_gmt_offset,
        s.s_tax_percentage
    FROM store s
    WHERE s.s_state = 'CA'                     -- predicate 1
      AND s.s_number_employees > 50            -- predicate 2
      AND s.s_gmt_offset BETWEEN -8.00 AND -5.00 -- predicate 3
      AND s.s_tax_percentage < 8.00            -- predicate 4
),
store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN distinct_stores ds ON ss.ss_store_sk = ds.s_store_sk
    WHERE ss.ss_ext_wholesale_cost > 1000      -- predicate 5
      AND ss.ss_ext_list_price < 15000         -- predicate 6
    GROUP BY ss.ss_store_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN distinct_stores ds ON sr.sr_store_sk = ds.s_store_sk
    WHERE sr.sr_return_ship_cost > 50          -- predicate 7
      AND sr.sr_store_credit > 10              -- predicate 8
      AND sr.sr_reversed_charge < 5            -- predicate 9
    GROUP BY sr.sr_store_sk
),
combined AS (
    SELECT
        ds.s_store_id,
        ds.s_city,
        ds.s_state,
        ds.s_store_sk,
        sa.total_sales,
        sa.total_profit,
        ra.total_return_amount,
        ra.total_fee,
        (sa.total_profit - ra.total_return_amount) AS net_profit_after_returns,
        ROW_NUMBER() OVER (PARTITION BY ds.s_state ORDER BY (sa.total_profit - ra.total_return_amount) DESC) AS state_rank
    FROM distinct_stores ds
    JOIN store_sales_agg sa ON ds.s_store_sk = sa.ss_store_sk
    JOIN store_returns_agg ra ON ds.s_store_sk = ra.sr_store_sk
    WHERE sa.total_sales > 50000               -- predicate 10
      AND sa.total_profit > 10000               -- predicate 11
),
final AS (
    SELECT
        c.s_store_id,
        c.s_city,
        c.s_state,
        c.total_sales,
        c.total_profit,
        c.total_return_amount,
        c.net_profit_after_returns,
        c.state_rank,
        AVG(c.net_profit_after_returns) OVER (PARTITION BY c.s_state) AS avg_state_net_profit
    FROM combined c
    WHERE EXISTS (
        SELECT 1
        FROM (
            SELECT DISTINCT sr2.sr_store_sk
            FROM store_returns sr2
            WHERE sr2.sr_return_amt_inc_tax > 1000
        ) sub
        WHERE sub.sr_store_sk = c.s_store_sk
    )
      AND c.state_rank <= 5
)
SELECT
    f.s_store_id,
    f.s_city,
    f.s_state,
    f.total_sales,
    f.total_profit,
    f.total_return_amount,
    f.net_profit_after_returns,
    f.state_rank,
    f.avg_state_net_profit
FROM final f
ORDER BY f.net_profit_after_returns DESC
LIMIT 100
