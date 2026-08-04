WITH cr_agg AS (
   SELECT
      cr_warehouse_sk,
      cr_ship_mode_sk,
      cr_returned_time_sk,
      cr_refunded_customer_sk,
      cr_refunded_cdemo_sk,
      SUM(cr_return_amount) AS sum_return_amount,
      AVG(cr_return_amount) AS avg_return_amount,
      COUNT(*)           AS cnt_returns,
      MIN(cr_return_amount) AS min_return_amount,
      MAX(cr_return_amount) AS max_return_amount
   FROM catalog_returns
   WHERE cr_return_quantity > 1
     AND cr_return_amount > 10.00
     AND cr_return_tax BETWEEN 0.5 AND 5.0
     AND cr_fee < 2.0
     AND cr_return_ship_cost IS NOT NULL
     AND cr_returned_date_sk BETWEEN 2450000 AND 2450999
   GROUP BY cr_warehouse_sk, cr_ship_mode_sk, cr_returned_time_sk,
            cr_refunded_customer_sk, cr_refunded_cdemo_sk
),
ranked AS (
   SELECT
      w.w_warehouse_name,
      sm.sm_ship_mode_id,
      td.t_hour,
      c.c_first_name,
      c.c_last_name,
      cr.sum_return_amount,
      cr.avg_return_amount,
      cr.cnt_returns,
      CASE WHEN cr.sum_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
      ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.sum_return_amount DESC) AS rn
   FROM cr_agg cr
   FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
   LEFT JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE sm.sm_code = 'AIR'
     AND td.t_shift = 'first'
     AND w.w_state = 'CA'
     AND c.c_salutation = 'Mr.'
     AND cd.cd_gender = 'M'
     AND td.t_minute IN (11, 12, 13)
     AND sm.sm_contract = '2mM8l'
)
SELECT
   w_warehouse_name,
   sm_ship_mode_id,
   t_hour,
   c_first_name,
   c_last_name,
   sum_return_amount,
   avg_return_amount,
   cnt_returns,
   return_level,
   rn
FROM ranked
WHERE rn <= 3
ORDER BY w_warehouse_name, sum_return_amount DESC
LIMIT 100
