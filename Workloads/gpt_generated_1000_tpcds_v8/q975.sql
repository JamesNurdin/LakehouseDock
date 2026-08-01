WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_coupon_amt,
        cp.cp_catalog_number,
        sm.sm_type,
        hd.hd_income_band_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_ship_cost > 100
      AND cs.cs_coupon_amt > 0
      AND cs.cs_net_profit > 0
      AND cp.cp_catalog_number IN (3, 5, 7)
      AND sm.sm_type = 'AIR'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
),
set_a AS (
    SELECT
        cs_order_number,
        cs_net_profit,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_bill_hdemo_sk
    FROM filtered_sales
    WHERE cs_net_profit > 500
),
set_b AS (
    SELECT
        cs_order_number,
        cs_net_profit,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_bill_hdemo_sk
    FROM filtered_sales
    WHERE cs_net_profit <= 500
),
union_set AS (
    SELECT cs_order_number, cs_net_profit, cs_catalog_page_sk, cs_ship_mode_sk, cs_bill_hdemo_sk
    FROM set_a
    UNION
    SELECT cs_order_number, cs_net_profit, cs_catalog_page_sk, cs_ship_mode_sk, cs_bill_hdemo_sk
    FROM set_b
),
exclude_set AS (
    SELECT cs_order_number, cs_net_profit, cs_catalog_page_sk, cs_ship_mode_sk, cs_bill_hdemo_sk
    FROM filtered_sales
    WHERE cs_coupon_amt = 0
),
final_set AS (
    SELECT * FROM union_set
    EXCEPT
    SELECT * FROM exclude_set
)
SELECT
    f.cs_order_number,
    f.cs_net_profit,
    cp.cp_catalog_number,
    sm.sm_type,
    hd.hd_income_band_sk,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_number ORDER BY f.cs_net_profit DESC) AS rank_within_catalog,
    (
        SELECT SUM(cs_inner.cs_ext_sales_price)
        FROM tpcds.catalog_sales cs_inner
        WHERE cs_inner.cs_catalog_page_sk = f.cs_catalog_page_sk
    ) AS total_sales_price_for_page
FROM final_set f
JOIN tpcds.catalog_page cp ON f.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm ON f.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.household_demographics hd ON f.cs_bill_hdemo_sk = hd.hd_demo_sk
ORDER BY f.cs_net_profit DESC
OFFSET 0 LIMIT 100
