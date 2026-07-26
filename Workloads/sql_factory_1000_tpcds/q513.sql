WITH sales_per_item_month AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       cs.cs_sold_date_sk AS date_key,
       SUM(cs.cs_net_profit) AS month_net_profit,
       SUM(cs.cs_ext_sales_price) AS month_sales
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, i.i_product_name, cs.cs_sold_date_sk
),
returns_per_item_month AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       sr.sr_returned_date_sk AS date_key,
       SUM(sr.sr_net_loss) AS month_net_loss,
       SUM(sr.sr_return_amt) AS month_return_amt
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, i.i_product_name, sr.sr_returned_date_sk
)
SELECT
   s.i_product_name,
   s.date_key,
   s.month_net_profit,
   r.month_net_loss,
   (s.month_net_profit - COALESCE(r.month_net_loss, 0)) AS net_profit_after_returns,
   LAG(s.month_net_profit) OVER (PARTITION BY s.i_item_sk ORDER BY s.date_key) AS prev_month_profit,
   CASE
       WHEN (s.month_net_profit - COALESCE(r.month_net_loss, 0)) > COALESCE(LAG(s.month_net_profit) OVER (PARTITION BY s.i_item_sk ORDER BY s.date_key), 0) THEN 'PROFIT_INCREASE'
       ELSE 'PROFIT_DECREASE_OR_SAME'
   END AS profit_trend,
   ROW_NUMBER() OVER (PARTITION BY s.i_item_sk ORDER BY s.date_key DESC) AS recent_month_rank
FROM sales_per_item_month s
LEFT JOIN returns_per_item_month r
   ON s.i_item_sk = r.i_item_sk AND s.date_key = r.date_key
WHERE s.month_net_profit IS NOT NULL
ORDER BY net_profit_after_returns DESC
LIMIT 30
