WITH sales_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        SUM(cs.cs_net_paid_inc_ship) AS total_amount,
        (SELECT COUNT(*) FROM tpcds.catalog_sales) AS total_sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 500
      AND hd.hd_income_band_sk BETWEEN 10 AND 20
      AND cs.cs_item_sk IN (
            SELECT sr_item_sk
            FROM tpcds.store_returns
            WHERE sr_return_amt > 200
        )
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_dep_count
),
returns_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        SUM(sr.sr_return_amt) AS total_amount,
        (SELECT COUNT(*) FROM tpcds.catalog_sales) AS total_sales_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_fee > 20
      AND hd.hd_vehicle_count >= 1
      AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_ship_hdemo_sk = hd.hd_demo_sk
              AND cs2.cs_quantity > 5
        )
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_dep_count
)
SELECT hd_demo_sk, hd_income_band_sk, hd_dep_count, total_amount, total_sales_cnt
FROM sales_agg
UNION ALL
SELECT hd_demo_sk, hd_income_band_sk, hd_dep_count, total_amount, total_sales_cnt
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
