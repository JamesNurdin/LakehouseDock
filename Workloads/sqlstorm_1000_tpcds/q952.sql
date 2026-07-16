SELECT d.d_year,
       t.state,
       SUM(t.sales_amount) AS total_sales,
       SUM(CASE WHEN t.channel = 'store' THEN t.sales_amount ELSE 0 END) AS store_sales,
       SUM(CASE WHEN t.channel = 'web' THEN t.sales_amount ELSE 0 END) AS web_sales,
       SUM(CASE WHEN t.channel = 'catalog' THEN t.sales_amount ELSE 0 END) AS catalog_sales
FROM (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS sales_amount,
           s.s_state AS state,
           'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_net_paid,
           ca.ca_state,
           'web'
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_net_paid,
           cc.cc_state,
           'catalog'
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
) t
JOIN date_dim d ON t.date_sk = d.d_date_sk
WHERE d.d_year = 1999
GROUP BY d.d_year, t.state
ORDER BY total_sales DESC
LIMIT 100
