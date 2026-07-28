WITH agg AS (
    SELECT
        i.i_item_id,
        dr.d_year,
        dr.d_month_seq,
        SUM(cr.cr_return_amount)      AS total_return_amount,
        SUM(cr.cr_return_quantity)    AS total_return_qty,
        COUNT(*)                      AS return_cnt,
        AVG(cr.cr_return_amount)      AS avg_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim dr          ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN tpcds.time_dim td          ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN tpcds.item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer c_refund   ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN tpcds.household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN tpcds.promotion p          ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d_start     ON p.p_start_date_sk = d_start.d_date_sk
    JOIN tpcds.date_dim d_end       ON p.p_end_date_sk = d_end.d_date_sk
    JOIN tpcds.web_page wp          ON wp.wp_customer_sk = c_refund.c_customer_sk
    JOIN tpcds.date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN tpcds.web_site ws          ON ws.web_open_date_sk = d_wp_create.d_date_sk
    JOIN tpcds.date_dim d_ws_close  ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE dr.d_year = 2001
      AND td.t_hour BETWEEN 8 AND 12
      AND i.i_current_price > 20
      AND w.w_state = 'CA'
      AND hd_refund.hd_vehicle_count >= 2
      AND p.p_discount_active = 'Y'
      AND wp.wp_link_count > 10
    GROUP BY i.i_item_id, dr.d_year, dr.d_month_seq
)
SELECT
    agg.i_item_id,
    agg.d_year,
    agg.d_month_seq,
    agg.total_return_amount,
    agg.total_return_qty,
    agg.return_cnt,
    agg.avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amount DESC) AS rn_yearly_rank,
    (
        SELECT AVG(a2.total_return_amount)
        FROM agg a2
        WHERE a2.d_year = agg.d_year
    ) AS avg_return_amount_year
FROM agg
WHERE agg.total_return_amount > (
    SELECT AVG(total_return_amount) * 1.5 FROM agg
)
ORDER BY agg.d_year, rn_yearly_rank
LIMIT 100
