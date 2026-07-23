WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_reversed_charge,
        cr.cr_net_loss,
        sm.sm_ship_mode_id,
        sm.sm_type,
        td.t_meal_time,
        td.t_sub_shift,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_reversed_charge,
        wr.wr_net_loss,
        wr.wr_reason_sk
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE cr.cr_return_ship_cost > 150.00
      AND cr.cr_reversed_charge BETWEEN 50.00 AND 200.00
      AND sm.sm_type = 'AIR'
      AND td.t_meal_time = 'dinner'
      AND td.t_sub_shift = 'afternoon'
      AND wr.wr_reversed_charge > 20.00
      AND wr.wr_reason_sk IN (33, 11, 23)
      AND wr.wr_return_quantity >= 1
),
agg_per_mode_meal AS (
    SELECT
        sm_ship_mode_id,
        t_meal_time,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        AVG(cr_reversed_charge) AS avg_cr_rev_charge,
        AVG(wr_reversed_charge) AS avg_wr_rev_charge,
        SUM(ws_net_profit) AS sum_ws_net_profit,
        SUM(cr_net_loss) AS sum_cr_net_loss,
        SUM(wr_net_loss) AS sum_wr_net_loss
    FROM joined_data
    GROUP BY sm_ship_mode_id, t_meal_time
)
SELECT
    sm_ship_mode_id,
    t_meal_time,
    cnt_returns,
    sum_return_amount,
    sum_wr_return_amt,
    avg_cr_rev_charge,
    avg_wr_rev_charge,
    sum_ws_net_profit,
    sum_cr_net_loss,
    sum_wr_net_loss,
    CASE
        WHEN (SELECT SUM(ws_net_profit) FROM web_sales) = 0 THEN NULL
        ELSE (sum_cr_net_loss + sum_wr_net_loss) / (SELECT SUM(ws_net_profit) FROM web_sales)
    END AS loss_to_profit_ratio
FROM agg_per_mode_meal
WHERE cnt_returns >= 5
  AND sum_return_amount > (SELECT AVG(cr_return_amount) FROM catalog_returns) * 2
ORDER BY loss_to_profit_ratio DESC NULLS LAST
LIMIT 100
