WITH inv_distinct AS (
    SELECT DISTINCT
        inv_item_sk,
        inv_date_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand
    FROM inventory
),
item_warehouse_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_class,
        w.w_state,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN inv_distinct inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2000
        AND d.d_month_seq BETWEEN 1200 AND 1210
        AND d.d_holiday = 'N'
        AND d.d_following_holiday = 'N'
        AND i.i_class IN ('scanners', 'hockey')
        AND i.i_current_price > 10
        AND w.w_state = 'CA'
        AND hd_ref.hd_vehicle_count > 1
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = cr.cr_item_sk
              AND wr.wr_returned_date_sk = d.d_date_sk
              AND wr.wr_return_quantity > 0
        )
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_class,
        w.w_state
),
class_summary AS (
    SELECT
        i_class,
        SUM(return_cnt) AS total_returns,
        SUM(total_net_loss) AS total_loss,
        AVG(total_net_loss) AS avg_loss_per_item
    FROM item_warehouse_agg
    GROUP BY i_class
    HAVING SUM(total_net_loss) > 1000
)
SELECT
    cs.i_class,
    cs.total_returns,
    cs.total_loss,
    cs.avg_loss_per_item
FROM class_summary cs
ORDER BY cs.total_loss DESC
LIMIT 100
