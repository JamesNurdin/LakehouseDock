WITH sales_filtered AS (
    SELECT
        ws.ws_bill_customer_sk,
        c.c_customer_id,
        i.i_item_sk,
        i.i_product_name,
        concat(i.i_brand, '-', i.i_color) AS brand_color,
        ws.ws_net_paid,
        ws.ws_order_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{3}')
)
SELECT
    sf.c_customer_id,
    sf.brand_color,
    SUBSTRING(sf.i_product_name, 1, 10) AS product_prefix,
    SUM(sf.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT sf.ws_order_number) AS distinct_orders
FROM sales_filtered sf
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = sf.ws_order_number
)
GROUP BY
    sf.c_customer_id,
    sf.brand_color,
    SUBSTRING(sf.i_product_name, 1, 10)
HAVING SUM(sf.ws_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
