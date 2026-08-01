WITH filtered_sales AS (
    SELECT
        d.d_year,
        regexp_extract(i.i_product_name, '(\\d{4})') AS product_code,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)holiday')
      AND i.i_product_name LIKE '%Premium%'
)
SELECT
    d_year,
    product_code,
    SUM(ws_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY d_year, product_code
ORDER BY d_year DESC, total_net_profit DESC
