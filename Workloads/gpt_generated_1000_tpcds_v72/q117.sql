WITH combined_households AS (
    SELECT DISTINCT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        'purchase' AS source,
        cs.cs_ext_sales_price AS amount
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_sales_price > 2000

    UNION ALL

    SELECT DISTINCT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        'return' AS source,
        sr.sr_return_amt AS amount
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 500
)
SELECT
    ch.hd_demo_sk,
    ch.source,
    COUNT(*) AS txn_count,
    SUM(ch.amount) AS total_amount,
    CASE WHEN EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = ch.hd_demo_sk
          AND cs2.cs_ext_sales_price > 3000
    ) THEN 'Y' ELSE 'N' END AS has_high_purchase,
    w_top.w_warehouse_name
FROM combined_households ch
CROSS JOIN LATERAL (
    SELECT w.w_warehouse_name
    FROM catalog_sales cs3
    JOIN warehouse w ON cs3.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs3.cs_bill_hdemo_sk = ch.hd_demo_sk
    GROUP BY w.w_warehouse_name
    ORDER BY SUM(cs3.cs_ext_sales_price) DESC
    LIMIT 1
) w_top
GROUP BY
    ch.hd_demo_sk,
    ch.source,
    w_top.w_warehouse_name
HAVING SUM(ch.amount) > 1000
ORDER BY total_amount DESC
LIMIT 100
