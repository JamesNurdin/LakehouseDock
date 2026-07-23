WITH warehouse_monthly AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_county,
        w.w_state,
        w.w_suite_number,
        date_dim.d_year,
        date_dim.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_store_credit) AS avg_store_credit
    FROM catalog_returns cr
    JOIN date_dim
        ON cr.cr_returned_date_sk = date_dim.d_date_sk
    JOIN item
        ON cr.cr_item_sk = item.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE
        date_dim.d_year = 2020
        AND date_dim.d_date >= DATE '2020-01-01'
        AND date_dim.d_date < DATE '2021-01-01'
        AND w.w_state IN ('NY', 'GA', 'MN')
        AND w.w_county NOT IN ('Bronx County')
        AND w.w_suite_number LIKE 'Suite %'
        AND cr.cr_store_credit > 100.00
        AND cr.cr_refunded_hdemo_sk BETWEEN 1000 AND 6000
        AND item.i_manufact_id IN (86, 338)
        AND item.i_container <> 'Unknown'
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_county,
        w.w_state,
        w.w_suite_number,
        date_dim.d_year,
        date_dim.d_month_seq
)
SELECT
    wm.w_warehouse_id,
    wm.w_warehouse_name,
    wm.w_state,
    wm.w_county,
    wm.w_suite_number,
    wm.d_year,
    wm.d_month_seq,
    wm.total_net_loss,
    wm.return_cnt,
    wm.avg_store_credit,
    (SELECT AVG(cr2.cr_net_loss)
     FROM catalog_returns cr2
     JOIN date_dim dd2 ON cr2.cr_returned_date_sk = dd2.d_date_sk
     WHERE dd2.d_year = 2020) AS overall_avg_net_loss_2020,
    (SELECT AVG(total_net_loss) FROM warehouse_monthly) AS avg_warehouse_monthly_net_loss,
    RANK() OVER (PARTITION BY wm.d_year ORDER BY wm.total_net_loss DESC) AS net_loss_rank,
    SUM(wm.total_net_loss) OVER (PARTITION BY wm.w_state) AS state_total_net_loss
FROM warehouse_monthly wm
WHERE wm.total_net_loss > (SELECT AVG(total_net_loss) FROM warehouse_monthly)
ORDER BY wm.total_net_loss DESC
LIMIT 20
