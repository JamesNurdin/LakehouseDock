WITH sales_orders AS (
        SELECT DISTINCT ws.ws_order_number
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2020
          AND regexp_like(p.p_promo_name, '(?i)discount')
          AND sm.sm_carrier LIKE 'GREAT%'
    ),
    return_orders AS (
        SELECT DISTINCT wr.wr_order_number
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2020
          AND regexp_like(r.r_reason_desc, '^Customer')
          AND EXISTS (
                SELECT 1
                FROM web_sales ws2
                JOIN ship_mode sm2 ON ws2.ws_ship_mode_sk = sm2.sm_ship_mode_sk
                WHERE ws2.ws_order_number = wr.wr_order_number
                  AND sm2.sm_carrier = 'TBS'
          )
    ),
    intersect_orders AS (
        SELECT ws_order_number AS order_number FROM sales_orders
        INTERSECT
        SELECT wr_order_number FROM return_orders
    )
SELECT
    io.order_number,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_category,
    regexp_extract(p.p_promo_name, '(?i)(discount\s*\d+%?)', 1) AS extracted_discount,
    concat('Carrier-', sm.sm_carrier) AS carrier_label,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
FROM intersect_orders io
JOIN web_sales ws ON ws.ws_order_number = io.order_number
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY io.order_number, p.p_promo_name, sm.sm_carrier
ORDER BY total_profit DESC
LIMIT 100
