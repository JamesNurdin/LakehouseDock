WITH joined_data AS (
  SELECT
    d.d_date,
    d.d_year,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    cs.cs_net_profit,
    sr.sr_net_loss,
    wr.wr_net_loss,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN reason r ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND hd.hd_vehicle_count >= 1
    AND cd.cd_gender = 'M'
)
SELECT
  d_year,
  d_date,
  i_item_id,
  i_product_name,
  w_warehouse_name,
  web_name,
  SUM(cs_net_profit) AS total_net_profit,
  SUM(COALESCE(sr_net_loss, 0)) AS total_store_loss,
  SUM(COALESCE(wr_net_loss, 0)) AS total_web_loss,
  MAX(inv_quantity_on_hand) AS latest_quantity_on_hand,
  ib_lower_bound,
  ib_upper_bound,
  r_reason_desc,
  cd_gender,
  hd_vehicle_count,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM joined_data
GROUP BY
  d_year,
  d_date,
  i_item_id,
  i_product_name,
  w_warehouse_name,
  web_name,
  ib_lower_bound,
  ib_upper_bound,
  r_reason_desc,
  cd_gender,
  hd_vehicle_count
HAVING SUM(cs_net_profit) > 1000
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
