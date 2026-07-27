/*
Goal: Identify the most profitable promotions for premium‑described items on dynamic web pages during the year 2022, showing the profit amount, a profit‑category flag, the discount extracted from the promotion name, a concatenated product‑promotion label and a short URL preview.
*/
WITH sales_data AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        wp.wp_type,
        i.i_product_name,
        ws.ws_net_profit,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_pct,
        concat(i.i_product_name, ' - ', p.p_promo_name) AS product_promo,
        substring(wp.wp_url, 1, 30) AS short_url
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2022
      AND regexp_like(i.i_item_desc, 'Premium')
      AND wp.wp_type LIKE 'dyn%'
)
SELECT
    d_year,
    p_promo_name,
    wp_type,
    i_product_name,
    discount_pct,
    SUM(ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws_net_profit) > 1000 THEN 'High' ELSE 'Normal' END AS profit_category,
    product_promo,
    short_url
FROM sales_data
GROUP BY
    d_year,
    p_promo_name,
    wp_type,
    i_product_name,
    discount_pct,
    product_promo,
    short_url
ORDER BY total_profit DESC
LIMIT 100
