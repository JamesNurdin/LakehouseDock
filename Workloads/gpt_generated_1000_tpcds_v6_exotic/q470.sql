WITH joined_data AS (
  SELECT
    d.d_year,
    cp.cp_department,
    sm.sm_type,
    p.p_discount_active,
    ca.ca_state,
    ws.ws_order_number,
    ws.ws_ext_sales_price AS web_sales_price,
    cs.cs_ext_sales_price AS catalog_sales_price,
    sr.sr_return_amt AS store_return_amt,
    wr.wr_return_amt AS web_return_amt,
    wp.wp_image_count,
    sr.sr_fee,
    wr.wr_account_credit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_addr_sk = ca.ca_address_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                       AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                       AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND cp.cp_department = 'Books'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND wp.wp_image_count > 2
    AND sr.sr_fee > 50
    AND wr.wr_account_credit < 50
)
SELECT
  d_year,
  cp_department,
  metric_type,
  SUM(metric_value) AS total_value,
  RANK() OVER (PARTITION BY metric_type ORDER BY SUM(metric_value) DESC) AS metric_rank
FROM (
  SELECT
    d_year,
    cp_department,
    'catalog_sales' AS metric_type,
    catalog_sales_price AS metric_value
  FROM joined_data
  UNION ALL
  SELECT
    d_year,
    cp_department,
    'store_returns' AS metric_type,
    store_return_amt AS metric_value
  FROM joined_data
) u
GROUP BY d_year, cp_department, metric_type
ORDER BY total_value DESC
LIMIT 100
