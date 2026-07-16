WITH sales_agg AS (
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category AS category,
   i.i_brand AS brand,
   cs.cs_item_sk AS item_sk,
   SUM(cs.cs_net_paid) AS total_sales_paid,
   SUM(cs.cs_net_profit) AS total_sales_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, cs.cs_item_sk
 UNION ALL
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category,
   i.i_brand,
   ss.ss_item_sk,
   SUM(ss.ss_net_paid) AS total_sales_paid,
   SUM(ss.ss_net_profit) AS total_sales_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, ss.ss_item_sk
 UNION ALL
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category,
   i.i_brand,
   ws.ws_item_sk,
   SUM(ws.ws_net_paid) AS total_sales_paid,
   SUM(ws.ws_net_profit) AS total_sales_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, ws.ws_item_sk
),
returns_agg AS (
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category AS category,
   i.i_brand AS brand,
   cr.cr_item_sk AS item_sk,
   SUM(cr.cr_net_loss) AS total_returns_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, cr.cr_item_sk
 UNION ALL
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category,
   i.i_brand,
   sr.sr_item_sk,
   SUM(sr.sr_net_loss) AS total_returns_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, sr.sr_item_sk
 UNION ALL
 SELECT
   d.d_year,
   d.d_month_seq AS month,
   i.i_category,
   i.i_brand,
   wr.wr_item_sk,
   SUM(wr.wr_net_loss) AS total_returns_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, wr.wr_item_sk
),
final_agg AS (
 SELECT
   s.d_year,
   s.month,
   s.category,
   s.brand,
   SUM(s.total_sales_paid) AS total_sales_paid,
   SUM(s.total_sales_profit) AS total_sales_profit,
   COALESCE(SUM(r.total_returns_loss), 0) AS total_returns_loss,
   (SUM(s.total_sales_profit) - COALESCE(SUM(r.total_returns_loss), 0)) AS net_real_profit
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON s.d_year = r.d_year
   AND s.month = r.month
   AND s.category = r.category
   AND s.brand = r.brand
   AND s.item_sk = r.item_sk
 GROUP BY s.d_year, s.month, s.category, s.brand
)
SELECT
  d_year,
  month,
  category,
  brand,
  total_sales_paid,
  total_sales_profit,
  total_returns_loss,
  net_real_profit,
  net_real_profit / NULLIF(total_sales_profit, 0) AS profit_margin,
  ROW_NUMBER() OVER (PARTITION BY d_year, month ORDER BY net_real_profit DESC) AS rank_within_month
FROM final_agg
WHERE net_real_profit > 0
ORDER BY d_year, month, rank_within_month
LIMIT 100
