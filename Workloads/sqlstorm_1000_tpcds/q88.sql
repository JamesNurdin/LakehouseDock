WITH catalog_agg AS (
   SELECT cs.cs_item_sk AS item_sk,
          SUM(cs.cs_ext_sales_price) AS sales,
          SUM(cs.cs_net_profit) AS profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_item_sk
), store_agg AS (
   SELECT ss.ss_item_sk AS item_sk,
          SUM(ss.ss_ext_sales_price) AS sales,
          SUM(ss.ss_net_profit) AS profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ss.ss_item_sk
), web_agg AS (
   SELECT ws.ws_item_sk AS item_sk,
          SUM(ws.ws_ext_sales_price) AS sales,
          SUM(ws.ws_net_profit) AS profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_item_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       COALESCE(ca.sales, 0) AS catalog_sales,
       COALESCE(sa.sales, 0) AS store_sales,
       COALESCE(wa.sales, 0) AS web_sales,
       COALESCE(ca.profit, 0) + COALESCE(sa.profit, 0) + COALESCE(wa.profit, 0) AS total_profit
FROM item i
LEFT JOIN catalog_agg ca ON ca.item_sk = i.i_item_sk
LEFT JOIN store_agg sa ON sa.item_sk = i.i_item_sk
LEFT JOIN web_agg wa ON wa.item_sk = i.i_item_sk
WHERE i.i_current_price > 50
ORDER BY total_profit DESC
LIMIT 20
