-- goal: Analyze net profit from catalog sales together with return losses and inventory by item category, hour of sale and customer income band, showing subtotals, running totals and ranking per category.
WITH
  -- Remove duplicate inventory rows (distinct usage)
  inv_dist AS (
    SELECT DISTINCT
      inv_item_sk,
      inv_warehouse_sk,
      inv_quantity_on_hand
    FROM inventory
  ),

  -- Join all required tables using the allowed keys, re‑using some tables under different aliases
  joined AS (
    SELECT
      i.i_category,
      i.i_category_id,
      t_sold.t_hour,
      ib.ib_income_band_sk,
      cs.cs_net_profit,
      cr.cr_net_loss,
      sr.sr_net_loss,
      wr.wr_net_loss,
      inv_dist.inv_quantity_on_hand,
      cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t_sold                ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc                 ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_ret           ON cr.cr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr         ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r_sr              ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr           ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr              ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inv_dist                  ON inv_dist.inv_item_sk = i.i_item_sk
                                      AND inv_dist.inv_warehouse_sk = w.w_warehouse_sk
    WHERE NOT EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_item_sk = i.i_item_sk
        AND wr2.wr_returned_date_sk = cs.cs_sold_date_sk
    )
  )

SELECT
  category,
  category_id,
  hour,
  income_band_sk,
  SUM(profit)                         AS total_profit,
  SUM(catalog_return_loss)            AS total_catalog_return_loss,
  SUM(store_return_loss)              AS total_store_return_loss,
  SUM(web_return_loss)                AS total_web_return_loss,
  SUM(inventory_on_hand)              AS total_inventory_on_hand,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS category_rank,
  SUM(SUM(profit)) OVER (
    ORDER BY SUM(profit) DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )                                   AS running_total_profit
FROM (
  SELECT
    i_category          AS category,
    i_category_id       AS category_id,
    t_hour              AS hour,
    ib_income_band_sk   AS income_band_sk,
    cs_net_profit       AS profit,
    cr_net_loss         AS catalog_return_loss,
    sr_net_loss         AS store_return_loss,
    wr_net_loss         AS web_return_loss,
    inv_quantity_on_hand AS inventory_on_hand
  FROM joined
) agg
GROUP BY GROUPING SETS (
  (category, category_id, hour, income_band_sk),
  (category, category_id, hour),
  (category, category_id),
  ()
)
HAVING SUM(profit) > 0
ORDER BY total_profit DESC
LIMIT 100
