WITH hourly_returns AS (
    SELECT
        t.t_hour AS hour_of_day,
        t.t_shift AS shift,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN inventory i
        ON i.inv_item_sk = cr.cr_item_sk
       AND i.inv_warehouse_sk = cr.cr_warehouse_sk
    WHERE cr.cr_call_center_sk IN (19, 40, 38)
      AND cr.cr_reason_sk NOT IN (16, 65)
      AND cr.cr_return_quantity >= 10
      AND cr.cr_return_tax > 0
    GROUP BY t.t_hour, t.t_shift
)
SELECT
    hour_of_day,
    shift,
    num_returns,
    total_return_amount,
    total_refunded_cash,
    avg_return_tax,
    total_return_quantity,
    avg_inventory_on_hand,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM hourly_returns
ORDER BY total_return_amount DESC
LIMIT 100
