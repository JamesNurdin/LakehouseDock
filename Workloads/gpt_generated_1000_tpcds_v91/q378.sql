WITH warehouse_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        COUNT(*) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_city
),
return_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_returning_hdemo_sk,
        t.t_hour,
        t.t_sub_shift,
        w.w_city,
        w.w_state,
        w.w_country,
        ROW_NUMBER() OVER (PARTITION BY w.w_city ORDER BY cr.cr_return_amount DESC) AS rn_city_return_amount,
        RANK() OVER (PARTITION BY w.w_city ORDER BY cr.cr_net_loss DESC) AS rank_city_net_loss
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        cr.cr_return_amount > 100.00
        AND t.t_hour IN (4, 14, 18)
        AND w.w_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM household_demographics hd
            WHERE hd.hd_demo_sk = cr.cr_returning_hdemo_sk
              AND hd.hd_vehicle_count >= 2
              AND hd.hd_income_band_sk BETWEEN 5 AND 10
        )
        AND NOT EXISTS (
            SELECT 1
            FROM household_demographics hd_ex
            WHERE hd_ex.hd_demo_sk = cr.cr_refunded_hdemo_sk
              AND hd_ex.hd_buy_potential = 'low'
        )
)
SELECT
    rd.cr_returned_date_sk,
    rd.cr_returned_time_sk,
    rd.t_hour,
    rd.t_sub_shift,
    rd.w_city,
    rd.w_state,
    rd.w_country,
    rd.cr_return_amount,
    rd.cr_net_loss,
    rd.rn_city_return_amount,
    rd.rank_city_net_loss,
    wa.total_returns,
    wa.total_net_loss,
    CASE
        WHEN rd.cr_net_loss > 0 THEN 'Loss'
        WHEN rd.cr_net_loss = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS loss_category,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr_inner
        WHERE cr_inner.cr_warehouse_sk = rd.cr_warehouse_sk
          AND cr_inner.cr_return_amount > 200
    ) AS high_value_return_count
FROM return_detail rd
JOIN warehouse_agg wa
    ON rd.cr_warehouse_sk = wa.w_warehouse_sk
WHERE rd.rn_city_return_amount <= 5
UNION
SELECT
    rd2.cr_returned_date_sk,
    rd2.cr_returned_time_sk,
    rd2.t_hour,
    rd2.t_sub_shift,
    rd2.w_city,
    rd2.w_state,
    rd2.w_country,
    rd2.cr_return_amount,
    rd2.cr_net_loss,
    rd2.rn_city_return_amount,
    rd2.rank_city_net_loss,
    wa2.total_returns,
    wa2.total_net_loss,
    CASE
        WHEN rd2.cr_net_loss > 0 THEN 'Loss'
        WHEN rd2.cr_net_loss = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS loss_category,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr_inner2
        WHERE cr_inner2.cr_warehouse_sk = rd2.cr_warehouse_sk
          AND cr_inner2.cr_return_amount > 200
    ) AS high_value_return_count
FROM return_detail rd2
JOIN warehouse_agg wa2
    ON rd2.cr_warehouse_sk = wa2.w_warehouse_sk
WHERE rd2.rank_city_net_loss <= 3
ORDER BY cr_returned_date_sk DESC, cr_return_amount DESC
LIMIT 100
