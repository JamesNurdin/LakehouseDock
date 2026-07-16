SELECT d.d_year, ws.ws_web_site_sk, ws.ws_sold_date_sk,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
       (SELECT sr2.sr_net_loss FROM store_returns sr2 WHERE sr2.sr_store_sk = 988 LIMIT 1) AS sample_net_loss
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE d.d_month_seq = 33 AND wsite.web_class = 'Unknown'
GROUP BY d.d_year, ws.ws_web_site_sk, ws.ws_sold_date_sk
HAVING d.d_year > 1935
