WITH unified_sales AS (
   SELECT cs.cs_sold_date_sk AS sold_date_sk,
          cs.cs_bill_customer_sk AS cust_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          cs.cs_quantity AS quantity,
          'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_customer_sk,
          ss.ss_item_sk,
          ss.ss_net_paid,
          ss.ss_net_profit,
          ss.ss_quantity,
          'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_bill_customer_sk,
          ws.ws_item_sk,
          ws.ws_net_paid,
          ws.ws_net_profit,
          ws.ws_quantity,
          'web' AS channel
   FROM web_sales ws
), sales_with_date AS (
   SELECT us.*,
          d.d_year,
          d.d_moy,
          date_trunc('month', d.d_date) AS month_date
   FROM unified_sales us
   JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
), sales_agg AS (
   SELECT channel,
          month_date,
          d_year,
          d_moy,
          item_sk,
          SUM(net_paid) AS total_net_paid,
          SUM(net_profit) AS total_net_profit,
          SUM(quantity) AS total_quantity
   FROM sales_with_date
   GROUP BY channel, month_date, d_year, d_moy, item_sk
), unified_returns AS (
   SELECT cr.cr_returned_date_sk AS returned_date_sk, cr.cr_net_loss AS net_loss, 'catalog' AS channel FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_returned_date_sk, sr.sr_net_loss, 'store' FROM store_returns sr
   UNION ALL
   SELECT wr.wr_returned_date_sk, wr.wr_net_loss, 'web' FROM web_returns wr
), returns_with_date AS (
   SELECT ur.*,
          d.d_year,
          d.d_moy,
          date_trunc('month', d.d_date) AS month_date
   FROM unified_returns ur
   JOIN date_dim d ON ur.returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
), returns_agg AS (
   SELECT channel, month_date, SUM(net_loss) AS total_net_loss
   FROM returns_with_date
   GROUP BY channel, month_date
), monthly_sales AS (
   SELECT channel,
          month_date,
          d_year,
          d_moy,
          SUM(total_net_profit) AS channel_month_profit,
          SUM(total_net_paid) AS channel_month_sales,
          SUM(total_quantity) AS channel_month_quantity
   FROM sales_agg
   GROUP BY channel, month_date, d_year, d_moy
), monthly_channel_adj AS (
   SELECT ms.channel,
          ms.month_date,
          ms.d_year,
          ms.d_moy,
          ms.channel_month_profit - COALESCE(r.total_net_loss, 0) AS adjusted_month_profit,
          ms.channel_month_sales,
          ms.channel_month_quantity,
          COALESCE(r.total_net_loss, 0) AS total_returns_loss
   FROM monthly_sales ms
   LEFT JOIN returns_agg r ON ms.channel = r.channel AND ms.month_date = r.month_date
), monthly_growth AS (
   SELECT mca.*,
          LAG(adjusted_month_profit) OVER (PARTITION BY channel ORDER BY month_date) AS prev_month_profit,
          CASE WHEN LAG(adjusted_month_profit) OVER (PARTITION BY channel ORDER BY month_date) IS NULL
                OR LAG(adjusted_month_profit) OVER (PARTITION BY channel ORDER BY month_date) = 0
               THEN NULL
               ELSE (adjusted_month_profit - LAG(adjusted_month_profit) OVER (PARTITION BY channel ORDER BY month_date))
                    / LAG(adjusted_month_profit) OVER (PARTITION BY channel ORDER BY month_date)
          END AS profit_growth
   FROM monthly_channel_adj mca
), top_item_per_month AS (
   SELECT sa.channel,
          sa.month_date,
          sa.item_sk,
          sa.total_quantity,
          ROW_NUMBER() OVER (PARTITION BY sa.channel, sa.month_date ORDER BY sa.total_quantity DESC) AS rn
   FROM sales_agg sa
)
SELECT mg.channel,
       mg.month_date,
       mg.adjusted_month_profit,
       mg.channel_month_sales,
       mg.channel_month_quantity,
       mg.total_returns_loss,
       mg.profit_growth,
       i.i_item_id,
       i.i_product_name,
       tip.total_quantity AS top_item_quantity
FROM monthly_growth mg
JOIN top_item_per_month tip
  ON mg.channel = tip.channel
 AND mg.month_date = tip.month_date
 AND tip.rn = 1
JOIN item i
  ON tip.item_sk = i.i_item_sk
WHERE mg.profit_growth IS NOT NULL
ORDER BY mg.channel, mg.month_date
