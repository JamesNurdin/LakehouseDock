WITH sales_with_mode AS (
   SELECT
       cs.cs_order_number,
       cs.cs_ext_discount_amt,
       cs.cs_sales_price,
       sm.sm_type,
       sm.sm_code
   FROM catalog_sales cs
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
   order_num,
   ROW_NUMBER() OVER (ORDER BY order_num) AS row_num
FROM (
   SELECT cs_order_number AS order_num
   FROM sales_with_mode
   WHERE sm_type = 'REGULAR'
     AND cs_ext_discount_amt > 1000
   INTERSECT
   SELECT cs_order_number AS order_num
   FROM sales_with_mode
   WHERE sm_code = 'AIR'
     AND cs_sales_price < 50
) intersected
ORDER BY row_num
OFFSET 0
LIMIT 100
