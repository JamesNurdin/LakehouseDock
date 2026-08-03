WITH sampled_item AS (
       SELECT *
       FROM item TABLESAMPLE BERNOULLI (10)
   ),
   store_agg AS (
       SELECT
           d.d_date,
           si.i_category,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           COUNT(*) AS txn_cnt,
           LAG(SUM(ss.ss_ext_sales_price)) OVER (PARTITION BY si.i_category ORDER BY d.d_date) AS prev_day_sales
       FROM store_sales ss
       JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       JOIN sampled_item si ON ss.ss_item_sk = si.i_item_sk
       WHERE d.d_year = 2001
       GROUP BY d.d_date, si.i_category
       HAVING SUM(ss.ss_ext_sales_price) > 5000
   ),
   web_agg AS (
       SELECT
           d.d_date,
           si.i_category,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS txn_cnt,
           LAG(SUM(ws.ws_ext_sales_price)) OVER (PARTITION BY si.i_category ORDER BY d.d_date) AS prev_day_sales
       FROM web_sales ws
       JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
       JOIN sampled_item si ON ws.ws_item_sk = si.i_item_sk
       WHERE d.d_year = 2001
       GROUP BY d.d_date, si.i_category
       HAVING SUM(ws.ws_ext_sales_price) > 5000
   )
SELECT *
FROM (
       SELECT
           s.d_date,
           s.i_category,
           s.total_sales,
           s.total_profit,
           CASE WHEN s.total_profit / NULLIF(s.total_sales, 0) > 0.2 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
           s.prev_day_sales
       FROM store_agg s
       UNION ALL
       SELECT
           w.d_date,
           w.i_category,
           w.total_sales,
           w.total_profit,
           CASE WHEN w.total_profit / NULLIF(w.total_sales, 0) > 0.2 THEN 'HIGH' ELSE 'LOW' END,
           w.prev_day_sales
       FROM web_agg w
   ) final
WHERE final.total_sales > (
       SELECT AVG(cat_sales)
       FROM (
           SELECT total_sales AS cat_sales FROM store_agg
           UNION ALL
           SELECT total_sales FROM web_agg
       ) sub
   )
ORDER BY final.d_date DESC, final.total_sales DESC
LIMIT 100
