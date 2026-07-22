WITH returns_summary AS (
  SELECT
    d.d_year AS return_year,
    cp.cp_department AS department,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cust_returning.c_customer_id) AS distinct_returning_customers,
    AVG(cr.cr_return_amount) AS avg_return_amount_per_return,
    SUM(CASE WHEN hd_refunded.hd_vehicle_count >= 2 THEN 1 ELSE 0 END) AS cnt_refunded_households_with_vehicles,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id) AS distinct_closed_stores,
    COUNT(*) AS total_returns
  FROM catalog_returns cr
  INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  INNER JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
  INNER JOIN customer cust_refunded ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
  INNER JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
  INNER JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
  INNER JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
  INNER JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  INNER JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  INNER JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  INNER JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
  INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  INNER JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND hd_refunded.hd_vehicle_count >= 2
    AND t.t_hour BETWEEN 9 AND 17
    AND cp.cp_department IN (
      SELECT DISTINCT cp2.cp_department
      FROM catalog_page cp2
      WHERE cp2.cp_type = 'Regular'
    )
    AND ib.ib_upper_bound <= 50000
  GROUP BY d.d_year, cp.cp_department
)
SELECT
  rs.return_year,
  rs.department,
  rs.total_return_amount,
  rs.total_return_qty,
  rs.distinct_returning_customers,
  rs.avg_return_amount_per_return,
  rs.cnt_refunded_households_with_vehicles,
  rs.total_inventory_on_hand,
  rs.distinct_closed_stores,
  rs.total_returns,
  (SELECT AVG(total_return_amount) FROM returns_summary WHERE return_year = rs.return_year) AS avg_return_amount_across_departments,
  CASE
    WHEN rs.total_return_amount > (SELECT AVG(total_return_amount) FROM returns_summary WHERE return_year = rs.return_year)
    THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS performance_category
FROM returns_summary rs
WHERE rs.total_return_amount > 10000
  AND rs.distinct_returning_customers >= 5
  AND rs.cnt_refunded_households_with_vehicles > 0
ORDER BY rs.return_year, rs.total_return_amount DESC
