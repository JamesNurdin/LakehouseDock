WITH sales AS (
   SELECT cs.cs_item_sk AS item_sk,
          d.d_year AS year,
          d.d_month_seq AS month_seq,
          d.d_moy AS month,
          cs.cs_net_profit AS net_profit,
          cs.cs_quantity AS qty_sold
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON cs.cs_bill_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
   UNION ALL
   SELECT ss.ss_item_sk,
          d.d_year,
          d.d_month_seq,
          d.d_moy,
          ss.ss_net_profit,
          ss.ss_quantity
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON ss.ss_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
   UNION ALL
   SELECT ws.ws_item_sk,
          d.d_year,
          d.d_month_seq,
          d.d_moy,
          ws.ws_net_profit,
          ws.ws_quantity
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON ws.ws_bill_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
),
returns AS (
   SELECT cr.cr_item_sk AS item_sk,
          d.d_year AS year,
          d.d_month_seq AS month_seq,
          d.d_moy AS month,
          cr.cr_net_loss AS net_loss,
          cr.cr_return_quantity AS qty_returned
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON cr.cr_refunded_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
   UNION ALL
   SELECT sr.sr_item_sk,
          d.d_year,
          d.d_month_seq,
          d.d_moy,
          sr.sr_net_loss,
          sr.sr_return_quantity
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON sr.sr_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
   UNION ALL
   SELECT wr.wr_item_sk,
          d.d_year,
          d.d_month_seq,
          d.d_moy,
          wr.wr_net_loss,
          wr.wr_return_quantity
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cdemo ON wr.wr_refunded_cdemo_sk = cdemo.cd_demo_sk
   WHERE cdemo.cd_gender = 'M' AND cdemo.cd_education_status = 'College'
),
combined AS (
   SELECT item_sk, year, month_seq, month, net_profit, 0.0 AS net_loss, qty_sold, 0 AS qty_returned
   FROM sales
   UNION ALL
   SELECT item_sk, year, month_seq, month, 0.0, net_loss, 0, qty_returned
   FROM returns
)
SELECT
   agg.year,
   agg.month,
   agg.i_category,
   agg.i_brand,
   agg.total_net_profit,
   agg.total_net_loss,
   agg.net_profit_after_returns,
   agg.total_qty_sold,
   agg.total_qty_returned,
   agg.return_rate,
   agg.avg_profit_per_unit,
   RANK() OVER (PARTITION BY agg.year ORDER BY agg.net_profit_after_returns DESC) AS category_rank_in_year,
   SUM(agg.net_profit_after_returns) OVER (PARTITION BY agg.i_category ORDER BY agg.year, agg.month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_category_profit
FROM (
   SELECT
      c.year,
      c.month,
      i.i_category,
      i.i_brand,
      SUM(c.net_profit) AS total_net_profit,
      SUM(c.net_loss) AS total_net_loss,
      SUM(c.net_profit) - SUM(c.net_loss) AS net_profit_after_returns,
      SUM(c.qty_sold) AS total_qty_sold,
      SUM(c.qty_returned) AS total_qty_returned,
      CASE WHEN SUM(c.qty_sold) = 0 THEN 0 ELSE SUM(c.qty_returned) * 1.0 / SUM(c.qty_sold) END AS return_rate,
      CASE WHEN (SUM(c.qty_sold) - SUM(c.qty_returned)) = 0 THEN 0 ELSE (SUM(c.net_profit) - SUM(c.net_loss)) * 1.0 / (SUM(c.qty_sold) - SUM(c.qty_returned)) END AS avg_profit_per_unit
   FROM combined c
   JOIN item i ON c.item_sk = i.i_item_sk
   GROUP BY c.year, c.month, i.i_category, i.i_brand
) agg
ORDER BY agg.year, agg.month, agg.net_profit_after_returns DESC
