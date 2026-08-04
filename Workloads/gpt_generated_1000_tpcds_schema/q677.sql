WITH cr_filtered AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_refunded_addr_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_ship_cost < 300
      AND cr.cr_refunded_addr_sk = 3405652
),
ws_filtered AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_net_paid_inc_ship,
        ws.ws_coupon_amt,
        ws.ws_order_number,
        ws.ws_ship_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_ship > 1000
      AND ws.ws_coupon_amt < 100
      AND ws.ws_ship_cdemo_sk > 500000
),
intersect_keys AS (
    SELECT cr.cr_order_number AS order_num
    FROM cr_filtered cr
    INTERSECT
    SELECT ws.ws_order_number
    FROM ws_filtered ws
),
base_join AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        ws.ws_net_paid_inc_ship,
        ws.ws_coupon_amt,
        td.t_am_pm,
        td.t_time
    FROM cr_filtered cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ws_filtered ws ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE cr.cr_order_number IN (SELECT order_num FROM intersect_keys)
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_return_amount > 2000
      )
),
agg AS (
    SELECT
        t_am_pm,
        t_time,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(ws_net_paid_inc_ship) AS sum_net_paid,
        COUNT(*) AS cnt
    FROM base_join
    GROUP BY GROUPING SETS (
        (t_am_pm, t_time),
        (t_am_pm),
        ()
    )
),
final AS (
    SELECT
        bj.cr_order_number,
        bj.t_am_pm,
        bj.t_time,
        bj.cr_return_amount,
        bj.ws_net_paid_inc_ship,
        CASE WHEN bj.cr_return_amount > 500 THEN 'HIGH' ELSE 'LOW' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY bj.t_am_pm ORDER BY bj.cr_return_amount DESC) AS rn_amount_desc,
        RANK() OVER (PARTITION BY bj.t_am_pm ORDER BY bj.ws_net_paid_inc_ship DESC) AS rk_paid_desc,
        lag(bj.cr_return_amount) OVER (PARTITION BY bj.t_am_pm ORDER BY bj.t_time) AS prev_return_amount,
        lead(bj.ws_net_paid_inc_ship) OVER (PARTITION BY bj.t_am_pm ORDER BY bj.t_time) AS next_net_paid,
        agg.sum_return_amount,
        agg.sum_net_paid,
        agg.cnt,
        lat.total_ret_amount,
        lat.total_paid_inc_ship
    FROM base_join bj
    LEFT JOIN agg
        ON (agg.t_am_pm = bj.t_am_pm AND agg.t_time = bj.t_time) OR (agg.t_am_pm = bj.t_am_pm AND agg.t_time IS NULL)
    LEFT JOIN LATERAL (
        SELECT
            SUM(bj2.cr_return_amount) AS total_ret_amount,
            SUM(bj2.ws_net_paid_inc_ship) AS total_paid_inc_ship
        FROM base_join bj2
        WHERE bj2.t_am_pm = bj.t_am_pm
    ) lat ON TRUE
)
SELECT
    cr_order_number,
    t_am_pm,
    t_time,
    return_category,
    cr_return_amount,
    ws_net_paid_inc_ship,
    prev_return_amount,
    next_net_paid,
    sum_return_amount,
    sum_net_paid,
    cnt,
    total_ret_amount,
    total_paid_inc_ship,
    rn_amount_desc,
    rk_paid_desc
FROM final
WHERE t_am_pm = 'PM'
  AND cr_return_amount BETWEEN 100 AND 1000
  AND ws_net_paid_inc_ship > 1500
ORDER BY cr_return_amount DESC, rn_amount_desc ASC
LIMIT 100
