WITH sales AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_amount,
    cs.cs_sold_date_sk AS date_sk,
    cc.cc_name AS call_center_name,
    sm.sm_carrier AS ship_carrier,
    'sale' AS transaction_type
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE i.i_category_id = 5
    AND i.i_manufact_id = 220
    AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
),
returns AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    cr.cr_return_quantity AS quantity,
    cr.cr_return_amount AS net_amount,
    cr.cr_returned_date_sk AS date_sk,
    cc.cc_name AS call_center_name,
    sm.sm_carrier AS ship_carrier,
    'return' AS transaction_type
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE i.i_category_id = 5
    AND i.i_manufact_id = 220
    AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY net_amount DESC
LIMIT 100
