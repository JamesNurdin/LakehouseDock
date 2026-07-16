SELECT
    sm.sm_carrier,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_revenue,
    CASE WHEN SUM(ws.ws_net_paid) = 0 THEN 0
         ELSE SUM(COALESCE(wr.wr_return_amt, 0)) / SUM(ws.ws_net_paid)
    END AS return_rate,
    RANK() OVER (ORDER BY (SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0))) DESC) AS revenue_rank
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
    AND wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450200
  AND sm.sm_carrier IN ('UPS', 'FEDEX')
GROUP BY sm.sm_carrier, r.r_reason_desc
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY net_revenue DESC
LIMIT 10
