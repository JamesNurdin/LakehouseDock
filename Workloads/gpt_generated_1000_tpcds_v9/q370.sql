WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cr.cr_returning_customer_sk,
        cr.cr_returning_hdemo_sk
    FROM
        catalog_returns cr
        TABLESAMPLE BERNOULLI (5)
    WHERE
        cr.cr_return_amount > 100
        AND cr.cr_return_quantity > 0
),
aggregated AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_id,
        d.d_year,
        r.r_reason_desc,
        SUM(fr.cr_return_amount) AS total_return_amount,
        AVG(fr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        GROUPING(cc.cc_call_center_id) AS g_cc,
        GROUPING(w.w_warehouse_id) AS g_warehouse,
        GROUPING(d.d_year) AS g_year
    FROM
        filtered_returns fr
        JOIN date_dim d
            ON fr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t
            ON fr.cr_returned_time_sk = t.t_time_sk
        JOIN call_center cc
            ON fr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w
            ON fr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r
            ON fr.cr_reason_sk = r.r_reason_sk
        JOIN catalog_page cp
            ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c
            ON fr.cr_returning_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
        JOIN inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2000
        AND d.d_month_seq = 1200
        AND t.t_am_pm = 'PM'
        AND cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
        AND i.inv_quantity_on_hand > 0
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_type = 'promo'
              AND cp2.cp_catalog_page_sk = fr.cr_catalog_page_sk
        )
    GROUP BY
        GROUPING SETS (
            (cc.cc_call_center_id, w.w_warehouse_id, d.d_year, r.r_reason_desc),
            (cc.cc_call_center_id, w.w_warehouse_id, d.d_year),
            (cc.cc_call_center_id, w.w_warehouse_id),
            (cc.cc_call_center_id),
            ()
        )
)
SELECT
    a.cc_call_center_id,
    a.w_warehouse_id,
    a.d_year,
    a.r_reason_desc,
    a.total_return_amount,
    a.avg_return_amount,
    a.return_cnt,
    a.g_cc,
    a.g_warehouse,
    a.g_year,
    RANK() OVER (PARTITION BY a.cc_call_center_id ORDER BY a.total_return_amount DESC) AS rank_by_warehouse
FROM
    aggregated a
ORDER BY
    a.total_return_amount DESC
LIMIT 100
