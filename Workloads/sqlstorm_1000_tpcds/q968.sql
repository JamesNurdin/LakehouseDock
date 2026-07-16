WITH
cat_sales AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_ext_sales_price) AS cat_sales
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
store_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
web_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
combined AS (
 SELECT
   COALESCE(ca.d_year, ss.d_year, ws.d_year) AS d_year,
   COALESCE(ca.month_seq, ss.month_seq, ws.month_seq) AS month_seq,
   COALESCE(ca.i_category, ss.i_category, ws.i_category) AS i_category,
   COALESCE(ca.i_class, ss.i_class, ws.i_class) AS i_class,
   COALESCE(ca.cat_net_profit, 0) + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
   COALESCE(ca.cat_sales, 0) + COALESCE(ss.store_sales, 0) + COALESCE(ws.web_sales, 0) AS total_sales
 FROM cat_sales ca
 FULL OUTER JOIN store_sales_agg ss
   ON ca.d_year = ss.d_year
  AND ca.month_seq = ss.month_seq
  AND ca.i_category = ss.i_category
  AND ca.i_class = ss.i_class
 FULL OUTER JOIN web_sales_agg ws
   ON COALESCE(ca.d_year, ss.d_year) = ws.d_year
  AND COALESCE(ca.month_seq, ss.month_seq) = ws.month_seq
  AND COALESCE(ca.i_category, ss.i_category) = ws.i_category
  AND COALESCE(ca.i_class, ss.i_class) = ws.i_class
)

SELECT
  d_year,
  month_seq,
  i_category,
  i_class,
  total_sales,
  total_net_profit,
  ROUND(total_net_profit / NULLIF(total_sales, 0) * 100, 2) AS profit_margin_percent,
  ROW_NUMBER() OVER (PARTITION BY d_year, month_seq ORDER BY total_net_profit DESC) AS profit_rank_month,
  DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS annual_sales_rank,
  SUM(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_year,
  LAG(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq) AS prior_month_sales,
  CASE 
    WHEN LAG(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq) IS NULL THEN NULL
    WHEN LAG(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq) = 0 THEN NULL
    ELSE ROUND((total_sales - LAG(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq)) / LAG(total_sales) OVER (PARTITION BY d_year ORDER BY month_seq) * 100, 2)
  END AS month_over_month_growth_percent
FROM combined
WHERE total_sales > 0
ORDER BY d_year, month_seq, profit_rank_month
LIMIT 200
