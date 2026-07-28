WITH inventory_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d_return.d_year,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sr.sr_return_amt) AS total_return_amt,
    inv_agg.total_qty AS total_inventory_qty
FROM store_returns sr
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_page cp
  ON cp.cp_end_date_sk = d_return.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_web
  ON wp.wp_creation_date_sk = d_web.d_date_sk
JOIN inventory_agg inv_agg
  ON inv_agg.inv_date_sk = d_web.d_date_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_return.d_year = 2001
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 30000
  AND ca.ca_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND r.r_reason_desc = 'Damaged'
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = sr.sr_reason_sk
          AND r2.r_reason_desc = 'Damaged'
    )
GROUP BY d_return.d_year, cp.cp_department, inv_agg.total_qty
HAVING SUM(sr.sr_return_amt) > 10000
ORDER BY total_return_amt DESC
LIMIT 100
