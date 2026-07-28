WITH sales_with_ratio AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_sales_price,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_paid_inc_ship / NULLIF(
            (SELECT avg(ws2.ws_net_paid_inc_ship)
             FROM web_sales ws2
             WHERE ws2.ws_ship_mode_sk = ws.ws_ship_mode_sk),
            0) AS profit_ratio
    FROM web_sales ws
    WHERE ws.ws_sales_price > 100
)
SELECT
    w.web_site_id,
    w.web_name,
    sm.sm_code,
    s.ws_order_number,
    s.ws_sales_price,
    s.ws_net_paid_inc_ship,
    s.profit_ratio,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_type_desc,
    RANK() OVER (PARTITION BY w.web_site_id ORDER BY s.ws_net_paid_inc_ship DESC) AS sales_rank
FROM sales_with_ratio s
JOIN web_site w
    ON s.ws_web_site_sk = w.web_site_sk
LEFT JOIN ship_mode sm
    ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE w.web_rec_start_date >= DATE '2000-01-01'
  AND w.web_city = 'Seattle'
  AND sm.sm_code IN ('AIR', 'SEA')
ORDER BY sales_rank
LIMIT 100
