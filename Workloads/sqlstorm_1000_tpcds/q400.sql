WITH catalog_data AS (
   SELECT d.d_year,
          d.d_month_seq,
          c.cc_state,
          SUM(cs.cs_net_profit) AS catalog_net_profit,
          SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
   WHERE d.d_year = 2002
   GROUP BY d.d_year, d.d_month_seq, c.cc_state
),
store_data AS (
   SELECT d.d_year,
          d.d_month_seq,
          s.s_state,
          SUM(ss.ss_net_profit) AS store_net_profit,
          SUM(ss.ss_ext_sales_price) AS store_sales_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2002
   GROUP BY d.d_year, d.d_month_seq, s.s_state
),
web_data AS (
   SELECT d.d_year,
          d.d_month_seq,
          w.web_state,
          SUM(ws.ws_net_profit) AS web_net_profit,
          SUM(ws.ws_ext_sales_price) AS web_sales_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE d.d_year = 2002
   GROUP BY d.d_year, d.d_month_seq, w.web_state
)
SELECT
   channel,
   year,
   month_seq,
   state,
   total_sales,
   total_profit,
   total_sales / NULLIF(total_profit, 0) AS sales_to_profit_ratio
FROM (
   SELECT 'catalog' AS channel,
          d_year AS year,
          d_month_seq AS month_seq,
          cc_state AS state,
          catalog_sales_amount AS total_sales,
          catalog_net_profit AS total_profit
   FROM catalog_data
   UNION ALL
   SELECT 'store',
          d_year,
          d_month_seq,
          s_state,
          store_sales_amount,
          store_net_profit
   FROM store_data
   UNION ALL
   SELECT 'web',
          d_year,
          d_month_seq,
          web_state,
          web_sales_amount,
          web_net_profit
   FROM web_data
) t
ORDER BY channel, year, month_seq, state
