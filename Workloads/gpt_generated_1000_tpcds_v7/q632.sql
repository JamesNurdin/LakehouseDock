WITH
    d_sold AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
    ),
    d_ship AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
    )
SELECT
    s.s_store_name,
    p.p_promo_name,
    d_sold.d_year,
    SUM(ws.ws_net_profit)               AS total_profit,
    SUM(wr.wr_net_loss)                 AS total_return_loss,
    SUM(ws.ws_quantity)                 AS total_quantity_sold,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    COUNT(DISTINCT wr.wr_return_quantity) AS return_cnt
FROM web_sales ws
JOIN d_sold               ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold       ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site site         ON ws.ws_web_site_sk = site.web_site_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_returns wr       ON ws.ws_order_number = wr.wr_order_number
JOIN reason r              ON wr.wr_reason_sk = r.r_reason_sk
JOIN d_ship               ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN inventory i          ON d_ship.d_date_sk = i.inv_date_sk
JOIN store s               ON d_ship.d_date_sk = s.s_closed_date_sk
JOIN catalog_sales cs     ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE t_sold.t_hour BETWEEN 9 AND 17
GROUP BY s.s_store_name, p.p_promo_name, d_sold.d_year
ORDER BY total_profit DESC
LIMIT 100
