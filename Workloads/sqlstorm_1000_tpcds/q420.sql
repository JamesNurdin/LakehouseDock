SELECT d.d_year AS year,
       'catalog' AS channel,
       SUM(cs.cs_net_profit) AS net_profit,
       COALESCE(SUM(cr.cr_net_loss), 0) AS net_loss
FROM date_dim d
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_date_sk = d.d_date_sk
GROUP BY d.d_year

UNION ALL

SELECT d.d_year,
       'store' AS channel,
       SUM(ss.ss_net_profit) AS net_profit,
       COALESCE(SUM(sr.sr_net_loss), 0) AS net_loss
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_returned_date_sk = d.d_date_sk
GROUP BY d.d_year

UNION ALL

SELECT d.d_year,
       'web' AS channel,
       SUM(ws.ws_net_profit) AS net_profit,
       COALESCE(SUM(wr.wr_net_loss), 0) AS net_loss
FROM date_dim d
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY 1, 2
