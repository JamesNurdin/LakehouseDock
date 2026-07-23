WITH base_returns AS (
    SELECT
        ca_ref.ca_state,
        ca_ref.ca_zip,
        i.i_category,
        td.t_hour,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_order_number,
        CASE 
            WHEN hd_ref.hd_vehicle_count > 1 THEN 'MULTI_VEHICLE'
            ELSE 'SINGLE_OR_NONE'
        END AS vehicle_category
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price >= 50.00
      AND ca_ref.ca_state = 'CA'
      AND hd_ref.hd_vehicle_count >= 0
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd_ret
          WHERE hd_ret.hd_demo_sk = wr.wr_returning_hdemo_sk
            AND hd_ret.hd_buy_potential = '501-1000'
      )
),
agg_by_category_hour AS (
    SELECT
        ca_state,
        ca_zip,
        i_category,
        t_hour,
        vehicle_category,
        SUM(wr_return_quantity) AS total_qty,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT wr_order_number) AS distinct_orders
    FROM base_returns
    GROUP BY ca_state, ca_zip, i_category, t_hour, vehicle_category
)
SELECT
    ca_state,
    i_category,
    AVG(total_net_loss) AS avg_net_loss_per_hour,
    SUM(total_qty) AS sum_qty,
    COUNT(*) AS num_groups,
    CASE WHEN SUM(total_qty) > 100 THEN 'BIG_VOLUME' ELSE 'SMALL_VOLUME' END AS volume_flag
FROM agg_by_category_hour
WHERE total_qty > 0
GROUP BY ca_state, i_category
HAVING AVG(total_net_loss) > 10.0
ORDER BY avg_net_loss_per_hour DESC
LIMIT 100
