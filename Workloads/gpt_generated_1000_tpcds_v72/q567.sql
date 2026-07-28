WITH sales_data AS (
  SELECT
    cp.cp_department AS dept,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    CONCAT(cp.cp_department, ':', CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END) AS dept_profit_label
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2001
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_sk = cs.cs_promo_sk
        AND regexp_like(p.p_promo_name, '^.*Discount.*$')
    )
    AND cp.cp_description LIKE '%clearance%'
  GROUP BY cp.cp_department
),
returns_data AS (
  SELECT
    wp.wp_type AS dept,
    -SUM(wr.wr_return_amt) AS total_sales,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    CONCAT(wp.wp_type, ':', CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'HIGH' ELSE 'LOW' END) AS dept_profit_label
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2001
    AND regexp_like(wp.wp_url, '^https?://.*?/sale/.*$')
    AND wp.wp_type LIKE '%promo%'
  GROUP BY wp.wp_type
),
max_date_cte AS (
  SELECT MAX(d_date) AS max_date FROM date_dim WHERE d_year = 2001
)
SELECT
  dept,
  total_sales,
  order_cnt,
  profit_category,
  dept_profit_label,
  (SELECT max_date FROM max_date_cte) AS reference_date
FROM sales_data
UNION ALL
SELECT
  dept,
  total_sales,
  order_cnt,
  profit_category,
  dept_profit_label,
  (SELECT max_date FROM max_date_cte) AS reference_date
FROM returns_data
ORDER BY total_sales DESC
LIMIT 100
