WITH joined_data AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_profit,
        cr.cr_return_amount,
        w.w_warehouse_name,
        w.w_state,
        w.w_country,
        sm.sm_carrier,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE sm.sm_carrier = 'FEDEX'
      AND w.w_country = 'USA'
      AND i.inv_quantity_on_hand > 200
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451100
)
SELECT
    w_warehouse_name,
    sm_carrier,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_profit) - SUM(cr_return_amount) AS net_profit_after_returns,
    RANK() OVER (ORDER BY SUM(cs_net_profit) - SUM(cr_return_amount) DESC) AS profit_rank
FROM joined_data
GROUP BY w_warehouse_name, sm_carrier
ORDER BY profit_rank
LIMIT 10
