WITH inv_date_agg AS (
    SELECT inv_date_sk, SUM(inv.inv_quantity_on_hand) AS total_inventory_on_date
    FROM inventory inv
    GROUP BY inv_date_sk
)
SELECT
    sm.sm_ship_mode_id AS ship_mode,
    d.d_year AS year,
    cd.cd_marital_status AS marital_status,
    hd.hd_buy_potential AS buy_potential,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
    SUM(COALESCE(ida.total_inventory_on_date, 0)) AS total_inventory_year,
    SUM(CASE WHEN ws.web_country = 'United States' THEN 1 ELSE 0 END) AS us_site_count
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN inv_date_agg ida
  ON d.d_date_sk = ida.inv_date_sk
LEFT JOIN web_site ws
  ON d.d_date_sk = ws.web_open_date_sk
WHERE d.d_year = 2020
  AND sm.sm_type = 'Air'
  AND cd.cd_gender = 'F'
  AND hd.hd_buy_potential = 'High'
  AND cr.cr_store_credit > 20
  AND cr.cr_return_quantity >= 10
GROUP BY
    sm.sm_ship_mode_id,
    d.d_year,
    cd.cd_marital_status,
    hd.hd_buy_potential
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
