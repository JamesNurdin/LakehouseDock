WITH
    ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    key_diff AS (
        SELECT ws.ws_order_number
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
        EXCEPT
        SELECT wr.wr_order_number
        FROM web_returns wr
    )
SELECT
    d_sale.d_year AS sale_year,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE sm.sm_code END AS ship_category,
    kd.ws_order_number,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_sales_price) AS avg_ext_sales,
    l.item_avg_price,
    t.val AS unnest_val
FROM ss_sample ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN time_dim t_sale
    ON ss.ss_sold_time_sk = t_sale.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sale.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_returned_date_sk = d_sale.d_date_sk
JOIN key_diff kd
    ON kd.ws_order_number = ws.ws_order_number
LEFT JOIN LATERAL (
    SELECT AVG(ws2.ws_ext_sales_price) AS item_avg_price
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = ws.ws_item_sk
) l ON true
CROSS JOIN UNNEST(ARRAY[CAST(ws.ws_quantity AS double), ws.ws_ext_sales_price]) AS t(val)
WHERE d_sale.d_current_year = 'Y'
  AND ss.ss_item_sk NOT IN (
        SELECT DISTINCT ws3.ws_item_sk
        FROM web_sales ws3
        WHERE ws3.ws_quantity > 1000
    )
GROUP BY
    d_sale.d_year,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE sm.sm_code END,
    kd.ws_order_number,
    l.item_avg_price,
    t.val
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
LIMIT 100
