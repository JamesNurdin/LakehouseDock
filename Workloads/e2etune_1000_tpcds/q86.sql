SELECT
    p.p_promo_name,
    p.p_channel_tv,
    wsit.web_name AS website,
    t.t_hour,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_revenue,
    RANK() OVER (PARTITION BY t.t_hour ORDER BY (SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_net_loss, 0))) DESC) AS revenue_rank
FROM web_sales ws
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
WHERE p.p_discount_active = 'Y'
  AND i.i_category = 'Electronics'
  AND t.t_hour BETWEEN 9 AND 21
GROUP BY
    p.p_promo_name,
    p.p_channel_tv,
    wsit.web_name,
    t.t_hour
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY net_revenue DESC
LIMIT 100
