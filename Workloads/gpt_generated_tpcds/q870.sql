WITH
  store_sales_item_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      i.i_item_sk,
      d.d_year,
      d.d_moy,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_ext_discount_amt) AS total_discount,
      SUM(ss.ss_net_profit) AS total_net_profit,
      SUM(p.p_cost) AS total_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, d.d_year, d.d_moy
  ),

  store_returns_item_agg AS (
    SELECT
      s.s_store_sk,
      i.i_item_sk,
      d.d_year,
      d.d_moy,
      SUM(sr.sr_net_loss) AS total_return_loss,
      SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, i.i_item_sk, d.d_year, d.d_moy
  ),

  inventory_monthly AS (
    SELECT
      i.i_item_sk,
      d.d_year,
      d.d_moy,
      SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
  )

SELECT
  ss.s_store_name,
  ss.d_year,
  ss.d_moy,
  ss.i_item_sk,
  ss.total_quantity,
  ss.total_net_paid,
  ss.total_discount,
  ss.total_net_profit - COALESCE(sr.total_return_loss, 0) AS net_profit_after_returns,
  ss.total_quantity - COALESCE(sr.total_return_quantity, 0) AS net_quantity_sold,
  im.total_inventory_qty,
  ss.total_discount / NULLIF(ss.total_quantity, 0) AS avg_discount_per_item,
  ss.total_quantity / NULLIF(im.total_inventory_qty, 1) AS inventory_turnover_ratio
FROM store_sales_item_agg ss
LEFT JOIN store_returns_item_agg sr
  ON ss.s_store_sk = sr.s_store_sk
  AND ss.i_item_sk = sr.i_item_sk
  AND ss.d_year = sr.d_year
  AND ss.d_moy = sr.d_moy
LEFT JOIN inventory_monthly im
  ON ss.i_item_sk = im.i_item_sk
  AND ss.d_year = im.d_year
  AND ss.d_moy = im.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 100
