WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_return_quantity,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    r.r_reason_desc,
    sm.sm_type,
    inv.inv_quantity_on_hand,
    cd.cd_gender,
    hd.hd_income_band_sk
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_fee > 30
    AND cr.cr_return_amount >= 5
    AND i.i_current_price BETWEEN 20 AND 300
    AND w.w_state = 'CA'
    AND r.r_reason_desc LIKE '%size%'
    AND sm.sm_type = 'AIR'
    AND EXISTS (
      SELECT 1 FROM customer_address ca
      WHERE ca.ca_address_sk = cr.cr_returning_addr_sk
        AND ca.ca_state = 'CA'
    )
),
agg AS (
  SELECT
    w_warehouse_name,
    i_category,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_qty,
    AVG(cr_fee) AS avg_fee,
    COUNT(*) AS cnt_returns
  FROM base
  GROUP BY w_warehouse_name, i_category, r_reason_desc
)
SELECT
  a.w_warehouse_name,
  a.i_category,
  a.r_reason_desc,
  a.total_return_amount,
  a.total_return_qty,
  a.avg_fee,
  a.cnt_returns,
  (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM agg a
WHERE a.total_return_amount > (SELECT AVG(total_return_amount) FROM agg)
ORDER BY a.total_return_amount DESC
LIMIT 100
