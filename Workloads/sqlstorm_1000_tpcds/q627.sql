WITH latest_inventory_one AS (
   SELECT inv_item_sk, inv_quantity_on_hand
   FROM (
       SELECT inv_item_sk,
              inv_quantity_on_hand,
              ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
       FROM inventory
   ) t
   WHERE rn = 1
)
SELECT
   year,
   month,
   i_item_sk,
   i_brand,
   i_class,
   channel,
   SUM(sales_quantity) AS total_sales_quantity,
   SUM(sales_net_paid) AS total_sales_amount,
   SUM(sales_net_profit) AS total_sales_profit,
   SUM(return_quantity) AS total_return_quantity,
   SUM(return_net_loss) AS total_return_loss,
   SUM(sales_net_profit) - SUM(return_net_loss) AS net_profit_after_returns,
   CASE WHEN SUM(sales_net_paid) > 0 THEN (SUM(sales_net_profit) - SUM(return_net_loss)) / SUM(sales_net_paid) ELSE NULL END AS profit_margin,
   SUM(inventory_on_hand) AS total_inventory_on_hand,
   CASE WHEN SUM(inventory_on_hand) > 0 THEN SUM(sales_quantity) / SUM(inventory_on_hand) ELSE NULL END AS sales_to_inventory_ratio,
   ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY (SUM(sales_net_profit) - SUM(return_net_loss)) DESC) AS profit_rank
FROM (
   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'catalog' AS channel,
       cs.cs_quantity AS sales_quantity,
       cs.cs_net_paid_inc_tax AS sales_net_paid,
       cs.cs_net_profit AS sales_net_profit,
       0 AS return_quantity,
       0 AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk

   UNION ALL

   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'store' AS channel,
       ss.ss_quantity AS sales_quantity,
       ss.ss_net_paid_inc_tax AS sales_net_paid,
       ss.ss_net_profit AS sales_net_profit,
       0 AS return_quantity,
       0 AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk

   UNION ALL

   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'web' AS channel,
       ws.ws_quantity AS sales_quantity,
       ws.ws_net_paid_inc_tax AS sales_net_paid,
       ws.ws_net_profit AS sales_net_profit,
       0 AS return_quantity,
       0 AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk

   UNION ALL

   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'catalog' AS channel,
       0 AS sales_quantity,
       0 AS sales_net_paid,
       0 AS sales_net_profit,
       cr.cr_return_quantity AS return_quantity,
       cr.cr_net_loss AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk

   UNION ALL

   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'store' AS channel,
       0 AS sales_quantity,
       0 AS sales_net_paid,
       0 AS sales_net_profit,
       sr.sr_return_quantity AS return_quantity,
       sr.sr_net_loss AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk

   UNION ALL

   SELECT
       d.d_year AS year,
       d.d_moy AS month,
       i.i_item_sk AS i_item_sk,
       i.i_brand AS i_brand,
       i.i_class AS i_class,
       'web' AS channel,
       0 AS sales_quantity,
       0 AS sales_net_paid,
       0 AS sales_net_profit,
       wr.wr_return_quantity AS return_quantity,
       wr.wr_net_loss AS return_net_loss,
       COALESCE(li.inv_quantity_on_hand, 0) AS inventory_on_hand
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN latest_inventory_one li ON li.inv_item_sk = i.i_item_sk
) s
GROUP BY GROUPING SETS (
   (year, month, i_item_sk, i_brand, i_class, channel),
   (year, month, i_brand, i_class, channel),
   (year, month, i_brand, i_class),
   (year, month, channel),
   (year, month),
   (year)
)
ORDER BY year, month, i_brand, i_class, channel
