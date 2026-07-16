WITH store_data AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name,
   SUM(ss.ss_net_profit) AS store_net_profit,
   SUM(ss.ss_ext_sales_price) AS store_sales,
   COUNT(*) AS store_transactions
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name
),
web_data AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name,
   SUM(ws.ws_net_profit) AS web_net_profit,
   SUM(ws.ws_ext_sales_price) AS web_sales,
   COUNT(*) AS web_transactions
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name
),
catalog_data AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name,
   SUM(cs.cs_net_profit) AS catalog_net_profit,
   SUM(cs.cs_ext_sales_price) AS catalog_sales,
   COUNT(*) AS catalog_transactions
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY
   d.d_year,
   d.d_month_seq,
   i.i_item_sk,
   i.i_product_name
),
combined AS (
 SELECT
   COALESCE(s.d_year, w.d_year, c.d_year) AS year,
   COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) AS month_seq,
   COALESCE(s.i_item_sk, w.i_item_sk, c.i_item_sk) AS item_sk,
   COALESCE(s.i_product_name, w.i_product_name, c.i_product_name) AS product_name,
   s.store_net_profit,
   w.web_net_profit,
   c.catalog_net_profit,
   s.store_sales,
   w.web_sales,
   c.catalog_sales,
   s.store_transactions,
   w.web_transactions,
   c.catalog_transactions
 FROM store_data s
 FULL OUTER JOIN web_data w
   ON s.d_year = w.d_year
   AND s.d_month_seq = w.d_month_seq
   AND s.i_item_sk = w.i_item_sk
 FULL OUTER JOIN catalog_data c
   ON COALESCE(s.d_year, w.d_year) = c.d_year
   AND COALESCE(s.d_month_seq, w.d_month_seq) = c.d_month_seq
   AND COALESCE(s.i_item_sk, w.i_item_sk) = c.i_item_sk
),
final AS (
 SELECT
   year,
   month_seq,
   item_sk,
   product_name,
   (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0)) AS total_net_profit,
   (COALESCE(store_sales, 0) + COALESCE(web_sales, 0) + COALESCE(catalog_sales, 0)) AS total_sales,
   (COALESCE(store_transactions, 0) + COALESCE(web_transactions, 0) + COALESCE(catalog_transactions, 0)) AS total_transactions,
   ROW_NUMBER() OVER (PARTITION BY year, month_seq ORDER BY (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0)) DESC) AS profit_rank,
   LAG((COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0))) OVER (PARTITION BY item_sk ORDER BY year, month_seq) AS prev_month_profit,
   ((COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0))
     - LAG((COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0))) OVER (PARTITION BY item_sk ORDER BY year, month_seq))
    / NULLIF(LAG((COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0))) OVER (PARTITION BY item_sk ORDER BY year, month_seq), 0) AS profit_change_ratio
 FROM combined
 WHERE (COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0) + COALESCE(catalog_net_profit, 0)) > 0
)
SELECT
 year,
 month_seq,
 item_sk,
 product_name,
 total_net_profit,
 total_sales,
 total_transactions,
 profit_rank,
 profit_change_ratio
FROM final
WHERE profit_rank <= 10
ORDER BY year, month_seq, profit_rank
