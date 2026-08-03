WITH avg_year AS (
   SELECT d.d_year,
          AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
sales_detail AS (
   SELECT
       cs.cs_order_number AS order_number,
       cs.cs_net_paid_inc_tax,
       d.d_year,
       CASE WHEN cs.cs_net_paid_inc_tax > (
                SELECT avg_net_paid
                FROM avg_year ay
                WHERE ay.d_year = d.d_year
            )
            THEN 'Above Avg'
            ELSE 'Below Avg'
       END AS performance,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_paid_inc_tax DESC) AS rn
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Electronics'
     AND i.i_item_sk IN (SELECT p.p_item_sk FROM promotion p WHERE p.p_discount_active = 'Y')
     AND cs.cs_net_paid_inc_tax > 500
),
returns_key AS (
   SELECT cr.cr_order_number AS order_number
   FROM catalog_returns cr
   JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
     AND cr.cr_return_amount > 1000
),
filtered_orders AS (
   SELECT order_number
   FROM sales_detail
   EXCEPT
   SELECT order_number FROM returns_key
)
SELECT sd.order_number,
       sd.cs_net_paid_inc_tax,
       sd.performance,
       sd.rn,
       sd.d_year
FROM sales_detail sd
WHERE sd.order_number IN (SELECT order_number FROM filtered_orders)
ORDER BY sd.d_year, sd.rn
LIMIT 100
