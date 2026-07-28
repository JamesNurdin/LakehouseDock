WITH catalog_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        hd.hd_vehicle_count,
        SUM(cs.cs_net_paid) AS total_amount,
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS revenue_category,
        'catalog_sales' AS source_type
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 5
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
    HAVING SUM(cs.cs_net_paid) > 5000
),
store_ret_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        hd.hd_vehicle_count,
        -SUM(sr.sr_refunded_cash) AS total_amount,
        CASE WHEN SUM(sr.sr_refunded_cash) > 2000 THEN 'High' ELSE 'Low' END AS revenue_category,
        'store_returns' AS source_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
    HAVING SUM(sr.sr_refunded_cash) > 1000
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_ret_agg
ORDER BY total_amount DESC
LIMIT 100
