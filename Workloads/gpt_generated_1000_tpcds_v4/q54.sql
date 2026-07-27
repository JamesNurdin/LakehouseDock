WITH base AS (
   SELECT
       d_sold.d_date AS sold_date,
       d_ship.d_date AS ship_date,
       d_ret.d_date AS return_date,
       sm.sm_ship_mode_id,
       r.r_reason_desc,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS transaction_cnt
   FROM catalog_returns cr
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship
     ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN date_dim d_ret
     ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN inventory i
     ON i.inv_date_sk = d_ret.d_date_sk
   WHERE
       d_ret.d_year = 2001
       AND sm.sm_code IN ('AIR', 'SEA')
       AND r.r_reason_desc LIKE '%warranty%'
       AND i.inv_quantity_on_hand > 0
       AND EXISTS (
           SELECT 1
           FROM store s
           WHERE s.s_closed_date_sk = d_ret.d_date_sk
             AND s.s_state = 'CA'
       )
   GROUP BY
       d_sold.d_date,
       d_ship.d_date,
       d_ret.d_date,
       sm.sm_ship_mode_id,
       r.r_reason_desc
)
SELECT
    sold_date,
    ship_date,
    return_date,
    sm_ship_mode_id,
    r_reason_desc,
    total_sales,
    total_return_amount,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY total_sales DESC
LIMIT 100
