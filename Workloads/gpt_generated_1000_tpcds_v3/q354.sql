WITH sales_pre AS (
    SELECT cs.cs_order_number,
           cs.cs_net_profit,
           i.i_brand,
           i.i_item_desc,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           ib.ib_upper_bound,
           w.w_warehouse_name,
           w.w_city
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
      AND i.i_brand LIKE 'Brand%'
      AND c.c_email_address LIKE '%@example.com'
      AND ib.ib_upper_bound >= 100000
),
sales_agg AS (
    SELECT
        i_brand,
        SUBSTRING(i_item_desc, 1, 20) AS short_desc,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        w_warehouse_name,
        w_city,
        cs_order_number,
        cs_net_profit
    FROM sales_pre
)
SELECT
    i_brand,
    short_desc,
    customer_name,
    w_warehouse_name,
    w_city,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_net_profit) AS total_profit
FROM sales_agg
GROUP BY i_brand, short_desc, customer_name, w_warehouse_name, w_city
ORDER BY total_profit DESC
LIMIT 100
