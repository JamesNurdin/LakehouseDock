WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_reversed_charge,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        sm.sm_type,
        sm.sm_code,
        w.w_warehouse_name,
        w.w_zip,
        r.r_reason_desc,
        cd.cd_gender
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_reversed_charge > 50
      AND cr.cr_fee < 30
      AND sm.sm_code IN ('SEA', 'AIR')
      AND w.w_zip = '55709'
      AND cs.cs_quantity > 1
      AND cd.cd_gender = 'M'
),
agg1 AS (
    SELECT
        w_warehouse_name,
        sm_type,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY ROLLUP (w_warehouse_name, sm_type)
)
SELECT
    a.w_warehouse_name,
    a.sm_type,
    a.total_return_amount,
    a.total_net_paid,
    a.return_cnt,
    a.total_return_amount / NULLIF(a.return_cnt, 0) AS avg_return_per_return
FROM agg1 a
WHERE a.w_warehouse_name IS NOT NULL
  AND a.sm_type IS NOT NULL
  AND a.total_return_amount > (
        SELECT AVG(total_return_amount)
        FROM agg1
        WHERE w_warehouse_name IS NOT NULL
    )
ORDER BY a.total_return_amount DESC
LIMIT 100
