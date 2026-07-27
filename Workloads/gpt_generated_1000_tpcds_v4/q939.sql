WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        i.i_item_id,
        p.p_promo_name,
        c.c_last_name,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
        REGEXP_EXTRACT(i.i_item_id, '[0-9]+') AS item_id_digits
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_last_name LIKE 'B%'
      AND REGEXP_LIKE(p.p_promo_name, 'Summer')
)
SELECT
    fs.p_promo_name,
    fs.i_brand,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_quantity) AS total_qty,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_net_profit) AS avg_profit,
    SUM(CASE WHEN REGEXP_LIKE(fs.i_item_desc, 'organic') THEN fs.ws_quantity ELSE 0 END) AS organic_qty,
    MAX(fs.full_product_name) AS example_product,
    MIN(fs.item_id_digits) AS min_item_digits
FROM filtered_sales fs
GROUP BY
    fs.p_promo_name,
    fs.i_brand
HAVING SUM(fs.ws_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
