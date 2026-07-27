WITH sales_returns_agg AS (
  SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    hd.hd_income_band_sk,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_return_loss,
    AVG(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss END) AS avg_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_net_paid) DESC) AS dept_sales_rank_state
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN catalog_returns cr
    ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_returning_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE
    ss.ss_net_paid > 0
    AND ss.ss_coupon_amt < 5000
    AND hd.hd_dep_count BETWEEN 1 AND 5
    AND hd.hd_vehicle_count >= 0
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND cp.cp_department = 'DEPARTMENT'
    AND cr.cr_return_quantity > 0
  GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    hd.hd_income_band_sk,
    ca.ca_state
)
SELECT
  sr.cp_department,
  sr.cp_catalog_page_number,
  sr.ca_state,
  sr.total_sales,
  sr.total_return_loss,
  sr.avg_return_loss,
  sr.dept_sales_rank_state,
  CASE
    WHEN sr.total_return_loss > 1000 THEN 'HIGH_LOSS'
    WHEN sr.total_return_loss > 0 THEN 'LOW_LOSS'
    ELSE 'NO_LOSS'
  END AS loss_category,
  (SELECT AVG(total_sales) FROM sales_returns_agg) AS overall_avg_sales
FROM sales_returns_agg sr
WHERE
  sr.avg_return_loss > 100
  AND sr.dept_sales_rank_state = 1
  AND sr.total_sales > (SELECT AVG(total_sales) FROM sales_returns_agg)
ORDER BY sr.total_sales DESC
LIMIT 100
