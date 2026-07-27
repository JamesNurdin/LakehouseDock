WITH
  cr AS (
    SELECT
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_call_center_sk,
      cr.cr_ship_mode_sk,
      cr.cr_reason_sk,
      cr.cr_return_amount,
      ti.t_hour AS cr_hour,
      i1.i_category AS cr_category
    FROM catalog_returns cr
    JOIN time_dim ti ON cr.cr_returned_time_sk = ti.t_time_sk
    JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  ),
  ws AS (
    SELECT
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_ship_mode_sk,
      ws.ws_ext_sales_price,
      ti2.t_hour AS ws_hour,
      i2.i_category AS ws_category,
      wp.wp_web_page_id,
      sm2.sm_contract
    FROM web_sales ws
    JOIN time_dim ti2 ON ws.ws_sold_time_sk = ti2.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
  ),
  joined AS (
    SELECT
      cc.cc_name,
      i1.i_category AS cr_category,
      i2.i_category AS ws_category,
      r.r_reason_desc,
      sm1.sm_type AS cr_ship_type,
      sm2.sm_type AS ws_ship_type,
      cr.cr_return_amount,
      ws.ws_ext_sales_price
    FROM cr
    JOIN ws ON cr.cr_item_sk = ws.ws_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
  ),
  aggregated AS (
    SELECT
      cc_name,
      cr_category,
      ws_category,
      r_reason_desc,
      cr_ship_type,
      ws_ship_type,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(ws_ext_sales_price) AS total_sales
    FROM joined
    GROUP BY
      cc_name,
      cr_category,
      ws_category,
      r_reason_desc,
      cr_ship_type,
      ws_ship_type
  )
SELECT
  cc_name,
  cr_category,
  ws_category,
  r_reason_desc,
  cr_ship_type,
  ws_ship_type,
  total_return_amount,
  total_sales,
  ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
