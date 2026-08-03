WITH union_agg AS (
    SELECT hd.hd_demo_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_ext_list_price > 1000
      AND hd.hd_dep_count >= 1
    GROUP BY hd.hd_demo_sk
    UNION
    SELECT hd.hd_demo_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_coupon_amt > 500
      AND hd.hd_vehicle_count > 0
    GROUP BY hd.hd_demo_sk
),
intersect_demo AS (
    SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count >= 3
    INTERSECT
    SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 0
),
base AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        ib.ib_income_band_sk,
        ib.ib_upper_bound
    FROM store_sales ss
    FULL OUTER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_ext_discount_amt > 0
      AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count <> -1)
      AND (ib.ib_upper_bound IS NULL OR ib.ib_upper_bound >= 50000)
)
SELECT 
    b.ss_sold_date_sk,
    b.hd_demo_sk,
    b.ib_income_band_sk,
    b.ib_upper_bound,
    b.ss_ext_sales_price,
    b.ss_coupon_amt,
    CASE 
        WHEN b.ss_coupon_amt > 500 THEN 'High Coupon'
        ELSE 'Low Coupon'
    END AS coupon_category,
    AVG(b.ss_net_profit) OVER (PARTITION BY b.ib_income_band_sk) AS avg_profit_by_income,
    RANK() OVER (PARTITION BY b.ib_income_band_sk ORDER BY b.ss_ext_sales_price DESC) AS sales_rank,
    ls.store_total_sales,
    (SELECT AVG(ss3.ss_net_profit)
     FROM store_sales ss3
     WHERE ss3.ss_hdemo_sk = b.hd_demo_sk) AS avg_profit_per_household
FROM base b
LEFT JOIN LATERAL (
    SELECT SUM(s2.ss_ext_sales_price) AS store_total_sales
    FROM store_sales s2
    WHERE s2.ss_store_sk = b.ss_store_sk
) ls ON true
WHERE b.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_demo)
  AND EXISTS (SELECT 1 FROM union_agg ua WHERE ua.hd_demo_sk = b.hd_demo_sk)
ORDER BY b.ib_upper_bound DESC NULLS LAST, sales_rank
LIMIT 100
