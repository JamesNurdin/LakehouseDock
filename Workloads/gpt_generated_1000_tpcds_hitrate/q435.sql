WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
)
SELECT
    COALESCE(p.p_promo_name, 'All Promotions') AS promo_name,
    COALESCE(sm.sm_type, 'All Ship Modes') AS ship_mode_type,
    CASE
        WHEN SUM(s.cs_net_profit) > 100000 THEN 'High'
        WHEN SUM(s.cs_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(s.cs_net_profit) AS total_profit,
    COUNT(DISTINCT s.cs_order_number) AS orders_cnt
FROM sales_base s
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON s.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON s.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE s.cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity > 200
    )
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = s.cs_promo_sk
          AND p2.p_channel_email = 'Y'
    )
  AND d_sold.d_year = 2001
GROUP BY ROLLUP (p.p_promo_name, sm.sm_type)
HAVING SUM(s.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
