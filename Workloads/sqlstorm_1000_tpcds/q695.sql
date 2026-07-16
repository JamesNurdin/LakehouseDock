WITH
  sales_union AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'Catalog' AS channel,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid_inc_ship_tax AS net_amount,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           'Store' AS channel,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid_inc_tax AS net_amount,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           'Web' AS channel,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid_inc_ship_tax AS net_amount,
           ws.ws_net_profit AS profit
    FROM web_sales ws
  ),
  returns_union AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           'Catalog' AS channel,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amt_inc_tax AS net_amount,
           cr.cr_net_loss AS loss
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk AS date_sk,
           'Store' AS channel,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_return_amt_inc_tax AS net_amount,
           sr.sr_net_loss AS loss
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk AS date_sk,
           'Web' AS channel,
           wr.wr_item_sk AS item_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_return_amt_inc_tax AS net_amount,
           wr.wr_net_loss AS loss
    FROM web_returns wr
  ),
  sales_by_date AS (
    SELECT su.date_sk,
           su.channel,
           SUM(su.quantity) AS total_quantity_sold,
           SUM(su.net_amount) AS total_net_amount,
           SUM(su.profit) AS total_profit
    FROM sales_union su
    GROUP BY su.date_sk, su.channel
  ),
  returns_by_date AS (
    SELECT ru.date_sk,
           ru.channel,
           SUM(ru.quantity) AS total_quantity_returned,
           SUM(ru.net_amount) AS total_return_amount,
           SUM(ru.loss) AS total_loss
    FROM returns_union ru
    GROUP BY ru.date_sk, ru.channel
  ),
  net_metrics AS (
    SELECT sbd.date_sk,
           sbd.channel,
           COALESCE(sbd.total_quantity_sold, 0) - COALESCE(rbd.total_quantity_returned, 0) AS net_quantity,
           COALESCE(sbd.total_net_amount, 0) - COALESCE(rbd.total_return_amount, 0) AS net_amount,
           COALESCE(sbd.total_profit, 0) - COALESCE(rbd.total_loss, 0) AS net_profit
    FROM sales_by_date sbd
    LEFT JOIN returns_by_date rbd
      ON sbd.date_sk = rbd.date_sk AND sbd.channel = rbd.channel
  ),
  date_enriched AS (
    SELECT nm.*,
           d.d_year,
           d.d_month_seq,
           ((d.d_month_seq - 1) % 12) + 1 AS month_of_year,
           d.d_date
    FROM net_metrics nm
    LEFT JOIN date_dim d
      ON nm.date_sk = d.d_date_sk
  ),
  monthly_agg AS (
    SELECT de.channel,
           de.d_year,
           de.month_of_year,
           SUM(de.net_profit) AS profit_this_month
    FROM date_enriched de
    GROUP BY de.channel, de.d_year, de.month_of_year
  ),
  growth_by_month AS (
    SELECT ma.channel,
           ma.d_year,
           ma.month_of_year,
           ma.profit_this_month,
           LAG(ma.profit_this_month) OVER (PARTITION BY ma.channel, ma.month_of_year ORDER BY ma.d_year) AS profit_same_month_last_year,
           CASE
             WHEN LAG(ma.profit_this_month) OVER (PARTITION BY ma.channel, ma.month_of_year ORDER BY ma.d_year) IS NULL
                  OR LAG(ma.profit_this_month) OVER (PARTITION BY ma.channel, ma.month_of_year ORDER BY ma.d_year) = 0 THEN NULL
             ELSE (ma.profit_this_month - LAG(ma.profit_this_month) OVER (PARTITION BY ma.channel, ma.month_of_year ORDER BY ma.d_year))
                  / LAG(ma.profit_this_month) OVER (PARTITION BY ma.channel, ma.month_of_year ORDER BY ma.d_year)
           END AS yoy_growth
    FROM monthly_agg ma
  ),
  top_items AS (
    SELECT su.channel,
           su.item_sk,
           i.i_product_name AS product_name,
           SUM(su.profit) AS item_total_profit,
           ROW_NUMBER() OVER (PARTITION BY su.channel ORDER BY SUM(su.profit) DESC) AS rn
    FROM sales_union su
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY su.channel, su.item_sk, i.i_product_name
    HAVING SUM(su.profit) > (
      SELECT AVG(inner_profit) FROM (
        SELECT SUM(su2.profit) AS inner_profit
        FROM sales_union su2
        WHERE su2.channel = su.channel
        GROUP BY su2.item_sk
      ) sub
    )
  ),
  top_items_limited AS (
    SELECT channel,
           item_sk,
           product_name,
           item_total_profit,
           rn
    FROM top_items
    WHERE rn <= 3
  ),
  final_report AS (
    SELECT CONCAT(gbm.channel, ' - ', CAST(gbm.d_year AS VARCHAR), '-M', CAST(gbm.month_of_year AS VARCHAR)) AS period,
           ROUND(gbm.profit_this_month, 2) AS profit_this_month,
           ROUND(gbm.yoy_growth * 100, 2) AS yoy_growth_percent,
           ti.item_sk,
           ti.product_name,
           ROUND(ti.item_total_profit, 2) AS item_total_profit
    FROM growth_by_month gbm
    LEFT JOIN top_items_limited ti
      ON gbm.channel = ti.channel
    WHERE gbm.profit_this_month > 0
  )
SELECT *
FROM final_report
ORDER BY period, profit_this_month DESC
