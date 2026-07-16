SELECT d.d_year,
       s.state,
       SUM(s.sales) AS total_sales,
       SUM(s.profit) AS total_profit
FROM (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cc.cc_state AS state,
         cs.cs_ext_sales_price AS sales,
         cs.cs_net_profit AS profit
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  UNION ALL
  SELECT ss.ss_sold_date_sk AS date_sk,
         st.s_state AS state,
         ss.ss_ext_sales_price AS sales,
         ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN store st ON ss.ss_store_sk = st.s_store_sk
  UNION ALL
  SELECT ws.ws_sold_date_sk AS date_sk,
         wsite.web_state AS state,
         ws.ws_ext_sales_price AS sales,
         ws.ws_net_profit AS profit
  FROM web_sales ws
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, s.state
ORDER BY total_profit DESC
LIMIT 100
