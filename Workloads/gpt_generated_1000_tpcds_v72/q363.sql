WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        td.t_hour,
        sm.sm_carrier,
        w.w_country,
        w.w_warehouse_id,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount DESC) AS rn_warehouse,
        wr.wr_return_quantity AS web_return_quantity,
        wr.wr_reversed_charge AS web_reversed_charge
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON td.t_time_sk = wr.wr_returned_time_sk
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_return_amount > 50
      AND w.w_country = 'United States'
      AND sm.sm_carrier = 'UPS'
      AND td.t_hour BETWEEN 8 AND 17
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count > 0
      AND (wr.wr_reversed_charge IS NULL OR wr.wr_reversed_charge < 200)
)
SELECT
    w_country,
    sm_carrier,
    loss_flag,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    SUM(CASE WHEN web_return_quantity IS NOT NULL THEN web_return_quantity ELSE 0 END) AS total_web_return_qty
FROM joined_data
GROUP BY CUBE (w_country, sm_carrier, loss_flag)
HAVING SUM(cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
