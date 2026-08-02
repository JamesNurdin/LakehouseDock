WITH sales_per_customer AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        i.i_brand AS brand,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store store_sales_s ON ss.ss_store_sk = store_sales_s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = ss.ss_customer_sk
    )
),
sales_agg AS (
    SELECT
        spc.store_sk,
        spc.item_sk,
        spc.brand,
        SUM(spc.ext_sales_price) AS total_sales,
        SUM(spc.net_profit) AS total_profit,
        COUNT(DISTINCT spc.customer_sk) AS distinct_customers
    FROM sales_per_customer spc
    GROUP BY spc.store_sk, spc.item_sk, spc.brand
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store store_return_s ON sr.sr_store_sk = store_return_s.s_store_sk
    JOIN item item_ret ON sr.sr_item_sk = item_ret.i_item_sk
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
),
intersected_stores AS (
    SELECT store_sk FROM (
        SELECT store_sk FROM sales_agg
        INTERSECT
        SELECT store_sk FROM returns_agg
    )
),
brand_subset AS (
    SELECT i_brand FROM item WHERE i_brand LIKE 'importo%'
),
brands_union AS (
    SELECT i_brand AS brand FROM item
    UNION
    SELECT s_market_desc AS brand FROM store
)
SELECT
    s_final.s_store_name,
    sa.brand,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ra.total_return_amt, 0) AS total_return_amt,
    (sa.total_sales - COALESCE(ra.total_return_amt, 0)) AS net_sales_minus_returns
FROM sales_agg sa
JOIN store s_final ON sa.store_sk = s_final.s_store_sk
JOIN item i_final ON sa.item_sk = i_final.i_item_sk
LEFT JOIN returns_agg ra ON sa.store_sk = ra.store_sk AND sa.item_sk = ra.item_sk
WHERE s_final.s_store_sk IN (SELECT store_sk FROM intersected_stores)
  AND sa.brand IN (SELECT i_brand FROM brand_subset)
  AND sa.brand IN (SELECT brand FROM brands_union)
ORDER BY net_sales_minus_returns DESC
LIMIT 100
