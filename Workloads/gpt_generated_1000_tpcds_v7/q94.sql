WITH
    sold_date AS (
        SELECT * FROM date_dim
    ),
    ship_date AS (
        SELECT * FROM date_dim
    ),
    open_date AS (
        SELECT * FROM date_dim
    ),
    close_date AS (
        SELECT * FROM date_dim
    ),
    ship_mode_alt AS (
        SELECT * FROM ship_mode
    ),
    warehouse_alt AS (
        SELECT * FROM warehouse
    )
SELECT
    d_sold.d_fy_year                         AS fiscal_year,
    sm.sm_type                               AS ship_type,
    ws_ws.web_market_manager                 AS market_manager,
    COUNT(DISTINCT ws.ws_order_number)       AS order_cnt,
    SUM(ws.ws_net_profit)                    AS total_profit,
    AVG(ws.ws_coupon_amt)                    AS avg_coupon
FROM web_sales ws
INNER JOIN sold_date d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN ship_date d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
INNER JOIN web_site ws_ws
    ON ws.ws_web_site_sk = ws_ws.web_site_sk
INNER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
INNER JOIN open_date d_open
    ON ws_ws.web_open_date_sk = d_open.d_date_sk
INNER JOIN close_date d_close
    ON ws_ws.web_close_date_sk = d_close.d_date_sk
LEFT JOIN ship_mode_alt sm_alt
    ON ws.ws_ship_mode_sk = sm_alt.sm_ship_mode_sk
LEFT JOIN warehouse_alt wh_alt
    ON ws.ws_warehouse_sk = wh_alt.w_warehouse_sk
WHERE d_sold.d_fy_year = 1913
  AND d_open.d_week_seq = 14
GROUP BY d_sold.d_fy_year, sm.sm_type, ws_ws.web_market_manager
ORDER BY total_profit DESC
LIMIT 100
