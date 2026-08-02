WITH base_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        d_ret.d_month_seq,
        wp.wp_type,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_quantity,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount,
        CASE
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
        AND wp.wp_access_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND d_ret.d_current_month = 'Y'
      AND w.w_state = 'CA'
      AND wp.wp_type IN ('feedback', 'general')
      AND cr.cr_return_quantity > 10
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, d_ret.d_month_seq, wp.wp_type
)
SELECT
    b.w_warehouse_id,
    b.w_warehouse_name,
    AVG(b.total_net_loss) AS avg_total_net_loss,
    SUM(b.total_return_amount) AS sum_total_return_amount,
    CASE
        WHEN AVG(b.total_net_loss) > 500 THEN 'Critical'
        ELSE 'Normal'
    END AS overall_loss_category,
    ROW_NUMBER() OVER (ORDER BY AVG(b.total_net_loss) DESC) AS rn
FROM base_agg b
GROUP BY b.w_warehouse_id, b.w_warehouse_name
ORDER BY avg_total_net_loss DESC
LIMIT 100
