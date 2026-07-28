WITH sales_summary AS (
    SELECT
        cs_bill_customer_sk,
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        AVG(cs_coupon_amt) AS avg_coupon_amt
    FROM catalog_sales
    WHERE cs_coupon_amt > 500
      AND cs_ext_sales_price > 1000
    GROUP BY cs_bill_customer_sk, cs_ship_mode_sk
),
carrier_counts AS (
    SELECT
        sm_ship_mode_sk,
        COUNT(DISTINCT sm_carrier) AS distinct_carriers
    FROM ship_mode
    GROUP BY sm_ship_mode_sk
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    hd.hd_buy_potential,
    sm.sm_carrier,
    sa.total_sales,
    sa.total_orders,
    sa.avg_coupon_amt,
    CASE
        WHEN sa.total_sales > 20000 THEN 'VIP'
        WHEN sa.total_sales > 10000 THEN 'Gold'
        ELSE 'Regular'
    END AS customer_segment,
    cc.distinct_carriers
FROM sales_summary sa
JOIN customer c
    ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN carrier_counts cc
    ON sm.sm_ship_mode_sk = cc.sm_ship_mode_sk
WHERE c.c_birth_month = 7
  AND hd.hd_buy_potential = '1001-5000'
  AND ca.ca_state = 'CA'
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    hd.hd_buy_potential,
    sm.sm_carrier,
    sa.total_sales,
    sa.total_orders,
    sa.avg_coupon_amt,
    CASE
        WHEN sa.total_sales > 20000 THEN 'VIP'
        WHEN sa.total_sales > 10000 THEN 'Gold'
        ELSE 'Regular'
    END,
    cc.distinct_carriers
ORDER BY sa.total_sales DESC
LIMIT 100
