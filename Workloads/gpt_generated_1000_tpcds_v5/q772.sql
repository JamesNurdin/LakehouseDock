WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_quantity,
        wp.wp_url,
        wp.wp_autogen_flag,
        wp.wp_type
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, 'promo[0-9]{2,}')
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_type LIKE 'content%'
)
SELECT
    i.i_brand AS brand,
    substring(i.i_product_name, 1, 4) AS product_prefix,
    d.d_year,
    COUNT(DISTINCT fs.ws_order_number) AS orders,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    SUM(fs.ws_net_paid) AS total_net_paid,
    CASE
        WHEN i.i_current_price > 100 THEN 'Premium'
        ELSE 'Standard'
    END AS price_category,
    regexp_extract(i.i_item_id, '[0-9]+') AS numeric_item_id,
    hd.hd_buy_potential
FROM filtered_sales fs
JOIN item i
    ON fs.ws_item_sk = i.i_item_sk
JOIN date_dim d
    ON fs.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON fs.ws_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
    i.i_brand,
    substring(i.i_product_name, 1, 4),
    d.d_year,
    CASE
        WHEN i.i_current_price > 100 THEN 'Premium'
        ELSE 'Standard'
    END,
    regexp_extract(i.i_item_id, '[0-9]+'),
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 20
