WITH sales_union AS (
   SELECT d.d_year AS year,
          s.s_state AS state,
          ss.ss_ext_sales_price AS ext_sales,
          ss.ss_net_profit AS profit,
          'store' AS channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT d.d_year,
          w.w_state,
          cs.cs_ext_sales_price,
          cs.cs_net_profit,
          'catalog'
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   UNION ALL
   SELECT d.d_year,
          ws.web_state,
          wss.ws_ext_sales_price,
          wss.ws_net_profit,
          'web'
   FROM web_sales wss
   JOIN date_dim d ON wss.ws_sold_date_sk = d.d_date_sk
   JOIN web_site ws ON wss.ws_web_site_sk = ws.web_site_sk
)
SELECT year,
       state,
       channel,
       SUM(ext_sales) AS total_sales,
       SUM(profit) AS total_profit,
       COUNT(*) AS transaction_count
FROM sales_union
WHERE year BETWEEN 2000 AND 2002
GROUP BY year, state, channel
ORDER BY year, state, total_sales DESC
