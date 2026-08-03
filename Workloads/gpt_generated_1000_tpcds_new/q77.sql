WITH base AS (
  SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    sm.sm_type,
    w.w_warehouse_name,
    w.w_state,
    hd.hd_income_band_sk,
    ws.ws_net_paid,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_returned_date_sk
  FROM catalog_page cp
  JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
       AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
)
SELECT
  cp_catalog_page_id,
  cs_order_number,
  cs_quantity,
  cs_net_profit,
  sm_type,
  w_warehouse_name,
  w_state,
  hd_income_band_sk,
  ws_net_paid,
  cr_return_quantity,
  cr_return_amount,
  RANK() OVER (PARTITION BY w_warehouse_name ORDER BY cs_net_profit DESC) AS profit_rank,
  CASE
    WHEN cr_return_amount > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) THEN 'HIGH_RETURN'
    ELSE 'NORMAL_RETURN'
  END AS return_category
FROM base
WHERE cp_department = 'Books'
  AND sm_type = 'AIR'
  AND w_state = 'CA'
  AND cs_quantity > 5
  AND cr_return_quantity < 10
  AND cr_return_amount > (
        SELECT MAX(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = base.cr_returned_date_sk
      )
ORDER BY cs_net_profit DESC, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
