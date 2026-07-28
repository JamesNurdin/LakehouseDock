WITH sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    i.i_item_sk,
    i.i_category,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(CASE WHEN sr.sr_net_loss IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS store_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE td.t_hour BETWEEN 8 AND 17
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk IN (
        SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000
    )
    AND r.r_reason_desc = 'Customer Not Found'
    AND w.w_state = 'TX'
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    i.i_item_sk,
    i.i_category
)
SELECT
  sa.s_store_sk,
  sa.s_store_name,
  sa.s_state,
  sa.i_category,
  sa.store_sales,
  sa.store_net_profit,
  sa.store_return_loss,
  sa.total_inventory_qty,
  (
    SELECT SUM(cs.cs_ext_sales_price)
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_item_sk = sa.i_item_sk
      AND cs.cs_sold_time_sk = (
          SELECT MIN(t2.t_time_sk)
          FROM time_dim t2
          WHERE t2.t_hour BETWEEN 8 AND 17
      )
      AND cp.cp_department = 'Electronics'
  ) AS catalog_sales_total,
  (
    SELECT SUM(ws.ws_ext_sales_price)
    FROM web_sales ws
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE ws.ws_item_sk = sa.i_item_sk
      AND we.web_state = 'CA'
  ) AS web_sales_total,
  CASE WHEN EXISTS (
    SELECT 1
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_item_sk = sa.i_item_sk
      AND sm.sm_type = 'AIR'
  ) THEN 1 ELSE 0 END AS has_air_ship_mode,
  ROW_NUMBER() OVER (PARTITION BY sa.s_state ORDER BY sa.store_net_profit DESC) AS state_store_rank,
  RANK() OVER (ORDER BY sa.store_net_profit DESC) AS global_profit_rank
FROM sales_agg sa
ORDER BY sa.store_net_profit DESC
LIMIT 100
