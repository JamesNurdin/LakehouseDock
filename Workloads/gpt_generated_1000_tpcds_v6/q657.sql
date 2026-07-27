WITH q1 AS (
   SELECT
       c.c_customer_sk,
       c.c_birth_country,
       cd.cd_gender,
       w.w_state,
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       0.0 AS wr_return_amt
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE c.c_birth_country = 'MEXICO'
     AND cd.cd_gender = 'F'
     AND hd.hd_income_band_sk = 3
     AND sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
     AND cs.cs_ext_sales_price > 1000
     AND EXISTS (
         SELECT 1 FROM web_returns wr
         WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
           AND wr.wr_return_amt > 500
     )
),
q2 AS (
   SELECT
       c.c_customer_sk,
       c.c_birth_country,
       cd.cd_gender,
       w.w_state,
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       wr.wr_return_amt
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE c.c_birth_country = 'JORDAN'
     AND cd.cd_marital_status = 'M'
     AND hd.hd_income_band_sk = 4
     AND sm.sm_type = 'RAIL'
     AND w.w_state = 'TX'
     AND cs.cs_ext_sales_price > 2000
     AND wr.wr_return_amt > 300
),
combined AS (
   SELECT * FROM q1
   UNION ALL
   SELECT * FROM q2
)
SELECT
   c_birth_country,
   cd_gender,
   w_state,
   COUNT(DISTINCT cs_order_number) AS order_cnt,
   SUM(cs_ext_sales_price) AS total_sales,
   SUM(cr_return_amount) AS total_return_amount,
   AVG(cr_return_quantity) AS avg_return_qty,
   SUM(wr_return_amt) AS total_web_return_amt,
   (SELECT MAX(cs3.cs_ext_sales_price) FROM catalog_sales cs3 WHERE cs3.cs_sold_date_sk = 2450890) AS max_sales_on_date
FROM combined
GROUP BY c_birth_country, cd_gender, w_state
HAVING SUM(cs_ext_sales_price) > 50000
   AND COUNT(DISTINCT cs_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
