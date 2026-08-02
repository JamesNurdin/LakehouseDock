/*
  Goal: Summarize total return amounts and distinct order/ticket counts for catalog and store returns, broken down by household income band and demographic keys, with subtotals (ROLLUP), ranking, and inclusion of warehouses that have no catalog returns (via a full outer join). The results from catalog and store sources are combined with UNION ALL, distinct rows are enforced before aggregation, and the final list is ordered and limited.
*/
WITH cat_agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_demo_sk,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number <= 15
    GROUP BY ROLLUP (hd.hd_income_band_sk, hd.hd_demo_sk)
),
store_agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_demo_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND ca.ca_state = 'CA'
    GROUP BY ROLLUP (hd.hd_income_band_sk, hd.hd_demo_sk)
),
unioned AS (
    SELECT DISTINCT
        'Catalog' AS source,
        hd_income_band_sk,
        hd_demo_sk,
        total_return_amount,
        distinct_orders AS distinct_cnt
    FROM cat_agg
    UNION ALL
    SELECT DISTINCT
        'Store' AS source,
        hd_income_band_sk,
        hd_demo_sk,
        total_return_amount,
        distinct_tickets AS distinct_cnt
    FROM store_agg
),
aggregated AS (
    SELECT
        source,
        hd_income_band_sk,
        hd_demo_sk,
        SUM(total_return_amount) AS total_return_amount,
        SUM(distinct_cnt) AS total_distinct_cnt
    FROM unioned
    GROUP BY ROLLUP (source, hd_income_band_sk, hd_demo_sk)
)
SELECT
    source,
    COALESCE(CAST(hd_income_band_sk AS VARCHAR), 'ALL') AS income_band,
    COALESCE(CAST(hd_demo_sk AS VARCHAR), 'ALL') AS demo_sk,
    total_return_amount,
    total_distinct_cnt,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_return_amount DESC) AS rank_by_return
FROM aggregated
ORDER BY source, total_return_amount DESC
LIMIT 100
