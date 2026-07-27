WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_item_desc,
        i.i_units,
        i.i_category,
        inv.inv_quantity_on_hand,
        w.w_state,
        hd.hd_vehicle_count,
        r.r_reason_desc,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_units = 'Gram'
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 200
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 2
      AND r.r_reason_desc LIKE '%damaged%'
),
aggregated AS (
    SELECT
        i_category,
        loss_category,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(inv_quantity_on_hand) AS avg_qty,
        COUNT(*) AS cnt_returns
    FROM joined_data
    GROUP BY i_category, loss_category
)
SELECT
    a.i_category,
    a.loss_category,
    a.total_net_loss,
    a.avg_qty,
    a.cnt_returns,
    CASE
        WHEN a.total_net_loss > (SELECT AVG(total_net_loss) FROM aggregated) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_vs_avg
FROM aggregated a
WHERE a.avg_qty > 300
ORDER BY a.total_net_loss DESC
LIMIT 20
