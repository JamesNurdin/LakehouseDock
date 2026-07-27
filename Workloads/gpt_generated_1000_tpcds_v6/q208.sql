WITH sales_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_tax,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        t.t_time_id,
        t.t_meal_time,
        c.c_customer_id,
        c.c_email_address
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)edition')
      AND t.t_time_id LIKE 'AAAAAAA%BAA%'
      AND substring(c.c_email_address, 1, 5) = 'user_'
)
SELECT
    s.i_brand,
    s.t_meal_time,
    regexp_extract(s.i_product_name, '^([A-Za-z]+)', 1) AS product_prefix,
    COUNT(*) AS orders,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax
FROM sales_filtered s
GROUP BY
    s.i_brand,
    s.t_meal_time,
    regexp_extract(s.i_product_name, '^([A-Za-z]+)', 1)
ORDER BY total_sales DESC
LIMIT 100
