WITH
    cr_filtered AS (
        SELECT
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cr.cr_refunded_customer_sk,
            cr.cr_call_center_sk,
            cr.cr_returned_date_sk,
            cr.cr_reason_sk,
            cc.cc_call_center_id,
            cc.cc_name,
            cc.cc_state,
            cc.cc_employees,
            dd.d_year,
            dd.d_dom,
            r.r_reason_sk,
            r.r_reason_desc
        FROM catalog_returns cr
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN date_dim dd
            ON cr.cr_returned_date_sk = dd.d_date_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer c_ref
            ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        WHERE
            cr.cr_return_quantity > 1
            AND cr.cr_return_amount > 100
            AND cr.cr_net_loss > 0
            AND cc.cc_employees >= 50
            AND cc.cc_state = 'TX'
            AND dd.d_year = 2002
            AND r.r_reason_sk IN (13, 18, 19)
            AND dd.d_dom = 12
    ),
    agg AS (
        SELECT
            cc_call_center_id,
            cc_name,
            d_year,
            r_reason_sk,
            r_reason_desc,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt,
            AVG(cr_net_loss) AS avg_net_loss
        FROM cr_filtered
        GROUP BY
            cc_call_center_id,
            cc_name,
            d_year,
            r_reason_sk,
            r_reason_desc
    ),
    final AS (
        SELECT
            cc_call_center_id,
            cc_name,
            d_year,
            r_reason_desc,
            total_return_amount,
            total_net_loss,
            return_cnt,
            avg_net_loss,
            (SELECT AVG(cr2.cr_net_loss)
             FROM catalog_returns cr2
             WHERE cr2.cr_reason_sk = agg.r_reason_sk) AS overall_avg_loss_by_reason,
            RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank_year,
            CASE
                WHEN total_net_loss > (SELECT AVG(total_net_loss) FROM agg) THEN 'Above Avg'
                ELSE 'Below Avg'
            END AS loss_category
        FROM agg
        WHERE total_return_amount > (SELECT AVG(total_return_amount) FROM agg)
    )
SELECT
    cc_call_center_id,
    cc_name,
    d_year,
    r_reason_desc,
    total_return_amount,
    total_net_loss,
    return_cnt,
    avg_net_loss,
    overall_avg_loss_by_reason,
    loss_rank_year,
    loss_category
FROM final
ORDER BY d_year, loss_rank_year
LIMIT 100
