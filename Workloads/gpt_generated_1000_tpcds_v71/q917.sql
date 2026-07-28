WITH filtered_sales AS (
  SELECT DISTINCT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_ext_list_price,
    cs.cs_coupon_amt,
    cs.cs_quantity,
    cs.cs_ship_date_sk,
    ca.ca_state,
    ca.ca_zip,
    sm.sm_code,
    sm.sm_carrier
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_ext_list_price > 1000.00
    AND cs.cs_ext_list_price < 20000.00
    AND cs.cs_coupon_amt = 0.00
    AND cs.cs_quantity >= 1
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND sm.sm_code = 'AIR'
    AND cs.cs_ship_date_sk BETWEEN 2450820 AND 2450900
),
agg_sales AS (
  SELECT
    sm_code,
    ca_state,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_ext_sales_price) AS min_sale,
    MAX(cs_ext_sales_price) AS max_sale
  FROM filtered_sales
  GROUP BY sm_code, ca_state
)
SELECT
  sm_code,
  ca_state,
  order_cnt,
  total_sales,
  avg_discount,
  min_sale,
  max_sale,
  SUM(total_sales) OVER (PARTITION BY sm_code ORDER BY ca_state) AS cumulative_sales_by_mode_state,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
