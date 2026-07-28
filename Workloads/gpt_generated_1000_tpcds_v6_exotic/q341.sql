WITH bill_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        i.i_item_id,
        i.i_category,
        sm.sm_type,
        wp.wp_url,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_manufact_id = 52
      AND i.i_units = 'Dozen'
      AND cs.cs_wholesale_cost > 20
      AND cs.cs_coupon_amt = 0.00
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_max_ad_count >= 2
),
ship_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        i.i_item_id,
        i.i_category,
        sm.sm_type,
        wp.wp_url,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_manufact_id = 52
      AND i.i_units = 'Dozen'
      AND cs.cs_wholesale_cost > 20
      AND cs.cs_coupon_amt = 0.00
      AND sm.sm_carrier = 'UPS'
      AND wp.wp_max_ad_count >= 2
)
SELECT
    category,
    gender,
    ship_type,
    SUM(ext_sales_price) AS total_sales,
    AVG(net_profit) AS avg_profit,
    COUNT(DISTINCT order_number) AS distinct_orders,
    MIN(ext_sales_price) AS min_sale,
    MAX(ext_sales_price) AS max_sale,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(ext_sales_price) DESC) AS category_rank
FROM (
    SELECT
        cs_ext_sales_price AS ext_sales_price,
        cs_net_profit AS net_profit,
        cs_order_number AS order_number,
        cd_gender AS gender,
        i_category AS category,
        sm_type AS ship_type
    FROM bill_sales
    UNION ALL
    SELECT
        cs_ext_sales_price AS ext_sales_price,
        cs_net_profit AS net_profit,
        cs_order_number AS order_number,
        cd_gender AS gender,
        i_category AS category,
        sm_type AS ship_type
    FROM ship_sales
) AS u
GROUP BY category, gender, ship_type
ORDER BY total_sales DESC
LIMIT 100
