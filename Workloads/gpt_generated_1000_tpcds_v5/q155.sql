WITH sales_agg AS (
    SELECT
        ws_web_site_sk,
        ws_ship_mode_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_quantity > 2
    GROUP BY ws_web_site_sk, ws_ship_mode_sk, ws_sold_date_sk
)
SELECT
    ws.web_name,
    sm.sm_type,
    d.d_year,
    d.d_quarter_name,
    sa.total_profit,
    sa.avg_discount,
    sa.order_cnt,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
FROM sales_agg sa
JOIN web_site ws
  ON sa.ws_web_site_sk = ws.web_site_sk
JOIN ship_mode sm
  ON sa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
  ON sa.ws_sold_date_sk = d.d_date_sk
WHERE
    sm.sm_type = 'OVERNIGHT'
    AND ws.web_state = 'CA'
    AND d.d_fy_quarter_seq = 11
ORDER BY sa.total_profit DESC
LIMIT 100
