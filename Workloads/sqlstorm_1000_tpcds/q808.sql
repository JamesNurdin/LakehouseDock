WITH
sales_union AS (
 SELECT
   ss.ss_item_sk AS item_sk,
   i.i_item_id AS item_id,
   COALESCE(i.i_color, 'UNKNOWN') AS color,
   ss.ss_quantity AS qty,
   ss.ss_net_paid AS net_paid,
   ss.ss_net_profit AS net_profit,
   ss.ss_sold_date_sk AS sold_date_sk,
   'store' AS channel
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk

 UNION ALL

 SELECT
   cs.cs_item_sk,
   i.i_item_id,
   COALESCE(i.i_color, 'UNKNOWN') AS color,
   cs.cs_quantity,
   cs.cs_net_paid,
   cs.cs_net_profit,
   cs.cs_sold_date_sk,
   'catalog' AS channel
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk

 UNION ALL

 SELECT
   ws.ws_item_sk,
   i.i_item_id,
   COALESCE(i.i_color, 'UNKNOWN') AS color,
   ws.ws_quantity,
   ws.ws_net_paid,
   ws.ws_net_profit,
   ws.ws_sold_date_sk,
   'web' AS channel
 FROM web_sales ws
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
aggregated_sales AS (
 SELECT
   item_sk,
   item_id,
   color,
   SUM(qty) AS total_qty,
   SUM(net_paid) AS total_sales,
   SUM(net_profit) AS total_profit,
   MIN(sold_date_sk) AS first_sold_date_sk,
   COUNT(DISTINCT channel) AS channel_count
 FROM sales_union
 GROUP BY item_sk, item_id, color
),
returns_union AS (
 SELECT
   cr.cr_item_sk AS item_sk,
   cr.cr_return_amount AS return_amount,
   cr.cr_net_loss AS net_loss,
   cr.cr_return_quantity AS return_qty
 FROM catalog_returns cr

 UNION ALL

 SELECT
   sr.sr_item_sk,
   sr.sr_return_amt,
   sr.sr_net_loss,
   sr.sr_return_quantity
 FROM store_returns sr

 UNION ALL

 SELECT
   wr.wr_item_sk,
   wr.wr_return_amt,
   wr.wr_net_loss,
   wr.wr_return_quantity
 FROM web_returns wr
),
aggregated_returns AS (
 SELECT
   item_sk,
   SUM(return_amount) AS total_return_amount,
   SUM(net_loss) AS total_return_net_loss,
   SUM(return_qty) AS total_return_qty
 FROM returns_union
 GROUP BY item_sk
),
joined AS (
 SELECT
   COALESCE(s.item_sk, r.item_sk) AS item_sk,
   COALESCE(s.item_id, i.i_item_id) AS item_id,
   COALESCE(s.color, i.i_color) AS color,
   COALESCE(s.total_qty, 0) AS total_qty,
   COALESCE(s.total_sales, 0) AS total_sales,
   COALESCE(s.total_profit, 0) AS total_profit,
   s.first_sold_date_sk,
   COALESCE(r.total_return_amount, 0) AS total_return_amount,
   COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
   (COALESCE(s.total_profit,0) - COALESCE(r.total_return_net_loss,0)) AS net_profit,
   COALESCE(s.channel_count,0) AS channel_count
 FROM aggregated_sales s
 FULL OUTER JOIN aggregated_returns r ON s.item_sk = r.item_sk
 LEFT JOIN item i ON i.i_item_sk = COALESCE(s.item_sk, r.item_sk)
),
daily_sales AS (
 SELECT
   su.item_sk,
   su.sold_date_sk,
   SUM(su.net_paid) AS daily_sales,
   SUM(su.net_profit) AS daily_profit
 FROM sales_union su
 GROUP BY su.item_sk, su.sold_date_sk
),
daily_profit AS (
 SELECT
   ds.item_sk,
   d.d_date,
   ds.daily_profit
 FROM daily_sales ds
 JOIN date_dim d ON ds.sold_date_sk = d.d_date_sk
),
profit_window AS (
 SELECT
   dp.item_sk,
   dp.d_date,
   SUM(dp.daily_profit) OVER (PARTITION BY dp.item_sk ORDER BY dp.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7d_ma,
   ROW_NUMBER() OVER (PARTITION BY dp.item_sk ORDER BY dp.d_date DESC) AS rn
 FROM daily_profit dp
),
latest_profit_window AS (
 SELECT
   item_sk,
   profit_7d_ma
 FROM profit_window
 WHERE rn = 1
),
ranked AS (
 SELECT
   j.item_sk,
   j.item_id,
   j.color,
   j.total_sales,
   j.total_qty,
   j.net_profit,
   j.first_sold_date_sk,
   lpw.profit_7d_ma,
   RANK() OVER (ORDER BY j.net_profit DESC, j.total_qty DESC) AS profit_rank,
   (SELECT MIN(d2.d_date)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE ss2.ss_item_sk = j.item_sk) AS earliest_purchase_date
 FROM joined j
 LEFT JOIN latest_profit_window lpw ON lpw.item_sk = j.item_sk
 WHERE j.total_sales > 10000
   AND EXISTS (
     SELECT 1
     FROM store_sales ss_ca
     JOIN store s_ca ON ss_ca.ss_store_sk = s_ca.s_store_sk
     WHERE ss_ca.ss_item_sk = j.item_sk
       AND s_ca.s_state = 'CA'
   )
)

SELECT
  item_id,
  color,
  CONCAT('Item: ', item_id, ' (Part ', COALESCE(color, 'UNKNOWN'), ')') AS item_desc,
  total_sales,
  total_qty,
  net_profit,
  profit_7d_ma,
  profit_rank,
  earliest_purchase_date,
  CASE
    WHEN total_qty = 0 THEN NULL
    ELSE total_sales / NULLIF(total_qty, 0)
  END AS avg_price_per_qty,
  CASE
    WHEN net_profit > 0 THEN 'PROFIT'
    WHEN net_profit = 0 THEN 'BREAKEVEN'
    ELSE 'LOSS'
  END AS profit_status,
  CASE
    WHEN REGEXP_LIKE(item_id, 'A') AND NOT REGEXP_LIKE(item_id, 'Z') THEN 'A_ONLY'
    ELSE 'OTHER'
  END AS flags,
  DATE_ADD('day', -7, (SELECT d_date FROM date_dim WHERE d_date_sk = first_sold_date_sk)) AS one_week_before_first_sale
FROM ranked
WHERE profit_rank <= 10
ORDER BY profit_rank, net_profit DESC
LIMIT 10
