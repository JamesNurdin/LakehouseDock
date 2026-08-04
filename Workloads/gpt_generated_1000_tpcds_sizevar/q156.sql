WITH returns_1914_ash AS (
   SELECT DISTINCT cr.cr_order_number AS order_number
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 1914
     AND w.w_street_name = 'Ash Laurel'
),
college_dep_returns AS (
   SELECT DISTINCT cr.cr_order_number AS order_number
   FROM catalog_returns cr
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_college_count > 0
)
SELECT order_number
FROM returns_1914_ash
EXCEPT
SELECT order_number
FROM college_dep_returns
ORDER BY order_number
LIMIT 100
