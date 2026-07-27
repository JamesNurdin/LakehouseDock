/*
Goal: Analyze store return performance by store, return reason, and customer income band, classify return volume, rank stores within each state, and filter to the top performers.
*/
WITH sr_agg AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        sr_addr_sk,
        sr_hdemo_sk,
        SUM(sr_return_amt)           AS total_return_amt,
        SUM(sr_return_quantity)      AS total_qty,
        AVG(sr_return_ship_cost)     AS avg_ship_cost,
        COUNT(*)                     AS cnt_returns
    FROM store_returns
    WHERE sr_return_ship_cost > 20.00                     -- predicate 1
      AND sr_return_amt       > 100.00                    -- predicate 2
      AND sr_return_quantity  >= 1                       -- predicate 3
      AND sr_return_tax       < 500.00                    -- predicate 4
    GROUP BY sr_store_sk, sr_reason_sk, sr_addr_sk, sr_hdemo_sk
),
final AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ca.ca_country,
        SUM(sr_agg.total_return_amt)   AS store_total_return,
        SUM(sr_agg.total_qty)          AS store_total_qty,
        AVG(sr_agg.avg_ship_cost)      AS store_avg_ship_cost,
        CASE
            WHEN SUM(sr_agg.total_return_amt) > 50000 THEN 'High'
            WHEN SUM(sr_agg.total_return_amt) > 20000 THEN 'Medium'
            ELSE 'Low'
        END                            AS return_category,
        ROW_NUMBER() OVER (
            PARTITION BY s.s_state
            ORDER BY SUM(sr_agg.total_return_amt) DESC
        )                               AS rn_state_rank
    FROM sr_agg
    JOIN store s
        ON sr_agg.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr_agg.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON sr_agg.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_gmt_offset BETWEEN -5.00 AND 5.00                         -- predicate 5
      AND ca.ca_country = 'United States'                               -- predicate 6
      AND ib.ib_upper_bound <= 100000                                    -- predicate 7
      AND r.r_reason_desc LIKE '%color%'                                 -- predicate 8
      AND s.s_tax_percentage > (
            SELECT AVG(s_tax_percentage) FROM store
        )                                                               -- scalar subquery predicate
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ca.ca_country
    HAVING SUM(sr_agg.total_return_amt) > 10000
)
SELECT
    s_store_id,
    s_store_name,
    s_state AS state,
    ib_lower_bound AS lower_income,
    ib_upper_bound AS upper_income,
    r_reason_desc AS reason_desc,
    store_total_return,
    store_total_qty,
    store_avg_ship_cost,
    return_category,
    rn_state_rank
FROM final
WHERE rn_state_rank <= 5
ORDER BY store_total_return DESC
LIMIT 100
