WITH agg AS (
   SELECT
       cp.cp_department,
       cp.cp_catalog_number,
       r.r_reason_desc,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
       COUNT(DISTINCT cr.cr_order_number) AS return_orders,
       COUNT(DISTINCT ws.ws_order_number) AS sales_orders
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cp.cp_department = 'Sports'
     AND cp.cp_type = 'Promotional'
     AND r.r_reason_desc LIKE '%damaged%'
     AND cd.cd_gender = 'M'
     AND cd.cd_education_status = 'College'
     AND cr.cr_return_amount > 100
     AND ws.ws_ext_tax > 50
     AND ws.ws_quantity >= 2
   GROUP BY cp.cp_department, cp.cp_catalog_number, r.r_reason_desc
)
SELECT
    cp_department,
    cp_catalog_number,
    r_reason_desc,
    total_return_amount,
    total_sales,
    return_orders,
    sales_orders,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_return_amount DESC) AS dept_return_rank
FROM agg
ORDER BY dept_return_rank, cp_catalog_number
