WITH base AS (
  SELECT
    s.s_store_id,
    d.d_year,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    sr.sr_net_loss,
    r.r_reason_desc,
    cp.cp_department,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    wp.wp_type,
    ws.web_name,
    CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cs.cs_ext_sales_price > 1000
    AND ws.web_state = 'CA'
)
SELECT
  b.s_store_id,
  b.d_year,
  SUM(b.cs_net_profit) AS total_net_profit,
  SUM(b.sr_net_loss) AS total_net_loss,
  COUNT(*) AS txn_cnt,
  AVG(b.inv_quantity_on_hand) AS avg_inventory,
  CASE WHEN SUM(b.cs_net_profit) - SUM(b.sr_net_loss) > 0 THEN 'GOOD' ELSE 'BAD' END AS overall_indicator,
  (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ) AS avg_sales_price_yr
FROM base b
GROUP BY b.s_store_id, b.d_year
HAVING SUM(b.cs_net_profit) > (
    SELECT AVG(cs3.cs_net_profit)
    FROM catalog_sales cs3
    JOIN date_dim d3 ON cs3.cs_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2001
  )
ORDER BY total_net_profit DESC
LIMIT 100
