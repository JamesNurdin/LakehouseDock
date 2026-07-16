SELECT
  d.d_year,
  d.d_month_seq,
  COALESCE(st.s_state, web.web_state) AS state,
  SUM(s.sales_amount) AS total_sales,
  SUM(s.sales_profit) AS total_profit,
  COUNT(*) AS transaction_cnt
FROM (
  SELECT
    ss.ss_sold_date_sk AS sold_date_sk,
    ss.ss_store_sk AS store_sk,
    NULL AS web_site_sk,
    ss.ss_net_paid AS sales_amount,
    ss.ss_net_profit AS sales_profit,
    ss.ss_ticket_number AS txn_id
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    NULL,
    ws.ws_web_site_sk,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_order_number
  FROM web_sales ws
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    NULL,
    NULL,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_order_number
  FROM catalog_sales cs
) s
LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
LEFT JOIN store st ON s.store_sk = st.s_store_sk
LEFT JOIN web_site web ON s.web_site_sk = web.web_site_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, d.d_month_seq, COALESCE(st.s_state, web.web_state)
ORDER BY d.d_year, d.d_month_seq, total_sales DESC
LIMIT 500
