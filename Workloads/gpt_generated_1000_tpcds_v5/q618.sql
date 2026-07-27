WITH sales_agg AS (
    SELECT
        cs_ship_mode_sk,
        cs_bill_hdemo_sk,
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_qty,
        AVG(cs_ext_discount_amt) AS avg_discount,
        MIN(cs_ship_date_sk) AS min_ship_date_sk,
        MAX(cs_ship_date_sk) AS max_ship_date_sk
    FROM catalog_sales
    WHERE cs_ext_sales_price > 0
    GROUP BY cs_ship_mode_sk, cs_bill_hdemo_sk, cs_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sm.sm_ship_mode_id,
    sm.sm_type,
    hd.hd_buy_potential,
    s.total_sales,
    s.total_qty,
    s.avg_discount,
    (s.avg_discount - (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales)) AS discount_diff,
    s.min_ship_date_sk,
    s.max_ship_date_sk
FROM sales_agg s
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
WHERE sm.sm_contract = 'YvxVaJI10'
  AND c.c_birth_day = 16
  AND hd.hd_income_band_sk = 7
  AND c.c_customer_id IN (
        SELECT DISTINCT c2.c_customer_id
        FROM customer c2
        WHERE c2.c_birth_day = 16
    )
ORDER BY s.total_sales DESC
LIMIT 100
