WITH base AS (
   SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cp.cp_department AS department,
        w.w_warehouse_name AS warehouse_name,
        t.t_shift AS shift,
        cd.cd_gender AS gender,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
        (
            SELECT avg(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
        ) AS dept_avg_return
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE cr.cr_return_quantity > 1
     AND cr.cr_return_amount > 50
     AND cr.cr_return_ship_cost BETWEEN 100 AND 1500
     AND t.t_am_pm = 'PM'
     AND w.w_state = 'CA'
     AND cd.cd_gender = 'M'
     AND cp.cp_type = 'WEB'
     AND NOT EXISTS (
         SELECT 1
         FROM inventory i
         WHERE i.inv_warehouse_sk = cr.cr_warehouse_sk
           AND i.inv_date_sk = cr.cr_returned_date_sk
     )
),
unioned AS (
   SELECT * FROM base WHERE return_amount > 200
   UNION DISTINCT
   SELECT * FROM base WHERE return_amount <= 200
)
SELECT
    order_number,
    return_amount,
    department,
    warehouse_name,
    shift,
    gender,
    amount_category,
    dept_avg_return,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY return_amount DESC) AS rn_dept,
    RANK() OVER (PARTITION BY department ORDER BY return_amount DESC) AS rank_dept
FROM unioned
ORDER BY department, rn_dept
LIMIT 100
