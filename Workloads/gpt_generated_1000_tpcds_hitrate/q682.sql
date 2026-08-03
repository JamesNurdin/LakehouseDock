WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_ship_addr_sk,
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 20
      AND cs.cs_coupon_amt < 3000
      AND cs.cs_ship_addr_sk = 2121279
      AND cs.cs_quantity >= 1
      AND cs.cs_ext_tax > 0
      AND cs.cs_ext_discount_amt BETWEEN 0 AND 500
),
customer_filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        c.c_first_sales_date_sk,
        c.c_current_hdemo_sk,
        c.c_preferred_cust_flag,
        c.c_last_review_date
    FROM customer c
    WHERE c.c_birth_month = 4
      AND c.c_first_sales_date_sk BETWEEN 2451247 AND 2452167
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_last_review_date IS NOT NULL
),
hd_filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM household_demographics hd
    WHERE hd.hd_dep_count = 0
      AND hd.hd_income_band_sk = 10
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential = 'HIGH'
)
SELECT
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    CASE WHEN fs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    SUM(fs.cs_net_profit) AS total_profit,
    AVG(fs.cs_sales_price) AS avg_sales_price,
    MIN(fs.cs_sales_price) AS min_sales_price,
    MAX(fs.cs_sales_price) AS max_sales_price
FROM filtered_sales fs
FULL OUTER JOIN customer_filtered c
    ON fs.cs_bill_customer_sk = c.c_customer_sk
FULL OUTER JOIN hd_filtered hd
    ON (CASE WHEN fs.cs_bill_hdemo_sk IS NOT NULL THEN fs.cs_bill_hdemo_sk ELSE c.c_current_hdemo_sk END) = hd.hd_demo_sk
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_sales cs2
    WHERE cs2.cs_order_number = fs.cs_order_number
      AND cs2.cs_coupon_amt > 4000
)
GROUP BY
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    CASE WHEN fs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_profit DESC
LIMIT 100
