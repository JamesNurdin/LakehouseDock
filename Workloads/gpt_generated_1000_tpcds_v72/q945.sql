WITH base AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_store_credit,
    cr.cr_return_quantity,
    cr.cr_item_sk,
    cr.cr_call_center_sk,
    cr.cr_returned_date_sk,
    cc.cc_company_name,
    cc.cc_sq_ft,
    cc.cc_closed_date_sk,
    cc.cc_open_date_sk,
    dd.d_date,
    dd.d_year,
    dd.d_current_year,
    inv.inv_quantity_on_hand
  FROM catalog_returns cr
  JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN inventory inv
    ON inv.inv_date_sk = dd.d_date_sk
  WHERE dd.d_current_year = 'Y'
    AND cc.cc_company_name IN ('anti','cally')
    AND cc.cc_sq_ft > 1000000
    AND cr.cr_store_credit > 100
    AND inv.inv_quantity_on_hand > 0
    AND NOT EXISTS (
      SELECT 1 FROM inventory i2
      WHERE i2.inv_item_sk = cr.cr_item_sk
        AND i2.inv_quantity_on_hand = 0
    )
)
SELECT
  cc_company_name,
  d_date,
  cr_return_amount,
  cr_store_credit,
  inv_quantity_on_hand,
  CASE WHEN cr_store_credit >= 500 THEN 'High' ELSE 'Low' END AS credit_category,
  ROW_NUMBER() OVER (PARTITION BY cc_company_name ORDER BY cr_return_amount DESC) AS rn
FROM base
ORDER BY credit_category DESC, rn
LIMIT 100
