WITH
  filtered_items AS (
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
    EXCEPT
    SELECT sr.sr_item_sk
    FROM store_returns sr
  ),
  item_dim AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_current_price
    FROM item i
    JOIN filtered_items fi ON i.i_item_sk = fi.cr_item_sk
  ),
  catalog_fact AS (
    SELECT cr.cr_item_sk,
           cr.cr_return_quantity,
           cr.cr_return_amount,
           cr.cr_warehouse_sk,
           cr.cr_ship_mode_sk,
           cr.cr_call_center_sk,
           cr.cr_catalog_page_sk,
           cr.cr_refunded_cdemo_sk,
           cr.cr_returning_cdemo_sk,
           cr.cr_refunded_hdemo_sk,
           cr.cr_returning_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
  ),
  web_fact AS (
    SELECT ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_ship_mode_sk,
           ws.ws_warehouse_sk,
           ws.ws_web_page_sk,
           ws.ws_web_site_sk,
           ws.ws_bill_cdemo_sk,
           ws.ws_ship_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
  ),
  store_fact AS (
    SELECT sr.sr_store_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
  ),
  joined AS (
    SELECT
      COALESCE(cf.cr_item_sk, wf.ws_item_sk) AS item_sk,
      cf.cr_return_quantity,
      cf.cr_return_amount,
      wf.ws_quantity,
      wf.ws_net_paid,
      id.i_product_name,
      cc.cc_name,
      cp.cp_description,
      sm.sm_type AS ship_mode_type,
      w.w_warehouse_name,
      cd_ref.cd_gender AS refunded_gender,
      cd_ret.cd_gender AS returning_gender,
      hd_ref.hd_income_band_sk AS refunded_income_band,
      hd_ret.hd_income_band_sk AS returning_income_band
    FROM catalog_fact cf
    FULL OUTER JOIN web_fact wf ON cf.cr_item_sk = wf.ws_item_sk
    JOIN item_dim id ON id.i_item_sk = COALESCE(cf.cr_item_sk, wf.ws_item_sk)
    LEFT JOIN call_center cc ON cf.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cf.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON (
      cf.cr_ship_mode_sk = sm.sm_ship_mode_sk OR wf.ws_ship_mode_sk = sm.sm_ship_mode_sk
    )
    LEFT JOIN warehouse w ON (
      cf.cr_warehouse_sk = w.w_warehouse_sk OR wf.ws_warehouse_sk = w.w_warehouse_sk
    )
    LEFT JOIN customer_demographics cd_ref ON cf.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_ret ON cf.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN household_demographics hd_ref ON cf.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_ret ON cf.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  )
SELECT
  j.i_product_name,
  j.cc_name,
  j.cp_description,
  SUM(j.cr_return_quantity) AS total_return_qty,
  SUM(j.cr_return_amount) AS total_return_amount,
  SUM(j.ws_quantity) AS total_web_quantity,
  SUM(j.ws_net_paid) AS total_web_net_paid,
  COUNT(DISTINCT j.ship_mode_type) AS distinct_ship_modes,
  COUNT(DISTINCT j.w_warehouse_name) AS distinct_warehouses,
  s.sr_store_sk
FROM joined j
RIGHT OUTER JOIN store_fact s ON s.sr_item_sk = j.item_sk
GROUP BY
  j.i_product_name,
  j.cc_name,
  j.cp_description,
  s.sr_store_sk
ORDER BY total_return_amount DESC
OFFSET 0 LIMIT 20
