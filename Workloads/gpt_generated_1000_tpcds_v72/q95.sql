WITH
  cs AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      td.t_meal_time,
      hd.hd_demo_sk,
      SUM(cs.cs_net_profit) AS catalog_net_profit,
      SUM(cs.cs_quantity)   AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td          ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (364, 117)
      AND td.t_meal_time = 'dinner'
      AND hd.hd_vehicle_count >= 1
    GROUP BY i.i_item_sk, i.i_product_name, td.t_meal_time, hd.hd_demo_sk
  ),
  ws AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      td.t_meal_time,
      hd.hd_demo_sk,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_quantity)   AS web_quantity
    FROM web_sales ws
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td          ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsite       ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (364, 117)
      AND td.t_meal_time = 'dinner'
      AND hd.hd_vehicle_count >= 1
    GROUP BY i.i_item_sk, i.i_product_name, td.t_meal_time, hd.hd_demo_sk
  ),
  cr AS (
    SELECT
      i.i_item_sk,
      td.t_meal_time,
      hd.hd_demo_sk,
      SUM(cr.cr_net_loss)   AS catalog_return_loss,
      SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td          ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc       ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (364, 117)
      AND td.t_meal_time = 'dinner'
      AND hd.hd_vehicle_count >= 1
    GROUP BY i.i_item_sk, td.t_meal_time, hd.hd_demo_sk
  ),
  wr AS (
    SELECT
      i.i_item_sk,
      td.t_meal_time,
      hd.hd_demo_sk,
      SUM(wr.wr_net_loss)   AS web_return_loss,
      SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN item i               ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td          ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (364, 117)
      AND td.t_meal_time = 'dinner'
      AND hd.hd_vehicle_count >= 1
    GROUP BY i.i_item_sk, td.t_meal_time, hd.hd_demo_sk
  ),
  sr AS (
    SELECT
      i.i_item_sk,
      td.t_meal_time,
      hd.hd_demo_sk,
      SUM(sr.sr_net_loss)   AS store_return_loss,
      SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN item i               ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td          ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_manufact_id IN (364, 117)
      AND td.t_meal_time = 'dinner'
      AND hd.hd_vehicle_count >= 1
    GROUP BY i.i_item_sk, td.t_meal_time, hd.hd_demo_sk
  ),
  inv AS (
    SELECT
      i.i_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),
  hd_income AS (
    SELECT
      hd.hd_demo_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
  )
SELECT
  cs.i_item_sk,
  cs.i_product_name,
  cs.t_meal_time,
  cs.catalog_net_profit,
  ws.web_net_profit,
  cr.catalog_return_loss,
  wr.web_return_loss,
  sr.store_return_loss,
  (cs.catalog_net_profit + ws.web_net_profit
   - COALESCE(cr.catalog_return_loss, 0)
   - COALESCE(wr.web_return_loss, 0)
   - COALESCE(sr.store_return_loss, 0)) AS net_profit,
  inv.total_inventory,
  hd_income.ib_lower_bound,
  hd_income.ib_upper_bound,
  RANK() OVER (PARTITION BY cs.t_meal_time ORDER BY (cs.catalog_net_profit + ws.web_net_profit
         - COALESCE(cr.catalog_return_loss, 0)
         - COALESCE(wr.web_return_loss, 0)
         - COALESCE(sr.store_return_loss, 0)) DESC) AS profit_rank
FROM cs
LEFT JOIN ws          ON cs.i_item_sk = ws.i_item_sk          AND cs.t_meal_time = ws.t_meal_time
LEFT JOIN cr          ON cs.i_item_sk = cr.i_item_sk          AND cs.t_meal_time = cr.t_meal_time
LEFT JOIN wr          ON cs.i_item_sk = wr.i_item_sk          AND cs.t_meal_time = wr.t_meal_time
LEFT JOIN sr          ON cs.i_item_sk = sr.i_item_sk          AND cs.t_meal_time = sr.t_meal_time
LEFT JOIN inv         ON cs.i_item_sk = inv.i_item_sk
LEFT JOIN hd_income   ON cs.hd_demo_sk = hd_income.hd_demo_sk
WHERE cs.hd_demo_sk IS NOT NULL
ORDER BY net_profit DESC
LIMIT 100
