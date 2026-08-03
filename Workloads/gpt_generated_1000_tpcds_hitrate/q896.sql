WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        COUNT(*) AS cnt_orders,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_quantity > 1
      AND cs.cs_net_paid > 0
      AND cs.cs_ext_tax < 50
      AND cs.cs_sales_price BETWEEN 5 AND 100
    GROUP BY cs.cs_order_number, cs.cs_item_sk, cs.cs_bill_customer_sk, cs.cs_promo_sk, cs.cs_ship_mode_sk
),
filtered_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1950 AND 1960
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    i.i_category,
    sm.sm_type,
    p.p_promo_name,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(s.sum_net_paid) AS total_sales_net,
    AVG(s.avg_quantity) AS avg_sales_quantity,
    CASE
        WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HighReturn'
        ELSE 'LowReturn'
    END AS return_level,
    COUNT(*) FILTER (WHERE ws.ws_sales_price > 30) AS high_price_web_sales
FROM sales_agg s
RIGHT OUTER JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = s.cs_order_number
JOIN item i
    ON i.i_item_sk = s.cs_item_sk
JOIN promotion p
    ON p.p_promo_sk = s.cs_promo_sk
JOIN customer c
    ON c.c_customer_sk = s.cs_bill_customer_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_order_number = s.cs_order_number
   AND ws.ws_item_sk = i.i_item_sk
JOIN (
    SELECT DISTINCT wp.wp_web_page_sk
    FROM web_page wp TABLESAMPLE BERNOULLI (10)
    WHERE wp.wp_type = 'content'
) wp_sample
    ON ws.ws_web_page_sk = wp_sample.wp_web_page_sk
WHERE EXISTS (SELECT 1 FROM filtered_customers fc WHERE fc.c_customer_sk = c.c_customer_sk)
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count >= 2
  AND inv.inv_quantity_on_hand > 0
  AND i.i_current_price > 20
  AND ws.ws_sales_price < 80
GROUP BY
    i.i_category,
    sm.sm_type,
    p.p_promo_name
ORDER BY total_sales_net DESC
LIMIT 100
