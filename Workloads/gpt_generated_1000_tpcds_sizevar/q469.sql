WITH
  intersect_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 10
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 10
  ),
  joined_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cp.cp_department,
      sm.sm_type,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      hd.hd_income_band_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      wp.wp_type
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON cs.cs_order_number = ws.ws_order_number
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 90000
      AND cs.cs_quantity > 5
      AND ws.ws_quantity > 5
  ),
  aggregated AS (
    SELECT
      cp_department,
      sm_type,
      ib_lower_bound,
      SUM(cs_ext_sales_price) AS total_sales,
      AVG(cs_ext_sales_price) AS avg_sales,
      COUNT(DISTINCT cs_order_number) AS order_cnt,
      MIN(cs_ext_sales_price) AS min_sale,
      MAX(cs_ext_sales_price) AS max_sale
    FROM joined_data
    GROUP BY ROLLUP (cp_department, sm_type, ib_lower_bound)
  ),
  ranked AS (
    SELECT
      cp_department,
      sm_type,
      ib_lower_bound,
      total_sales,
      avg_sales,
      order_cnt,
      min_sale,
      max_sale,
      ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_sales_rank
    FROM aggregated
  )
SELECT
  cp_department,
  sm_type,
  ib_lower_bound,
  total_sales,
  avg_sales,
  order_cnt,
  min_sale,
  max_sale,
  dept_sales_rank
FROM ranked
LIMIT 100
