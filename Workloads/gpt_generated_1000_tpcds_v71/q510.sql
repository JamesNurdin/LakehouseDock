WITH joined AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wp.wp_type,
        wp.wp_url,
        cr.cr_return_quantity,
        wr.wr_return_quantity
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Legal'
      AND cr.cr_refunded_cash > 100
      AND wr.wr_return_amt_inc_tax > 200
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
),
agg_rollup AS (
    SELECT
        c_customer_id,
        cp_department,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(wr_return_amt_inc_tax) AS sum_wr_return_amt_inc_tax,
        SUM(cr_net_loss + wr_net_loss) AS sum_total_net_loss
    FROM joined
    GROUP BY ROLLUP (c_customer_id, cp_department)
),
agg_type AS (
    SELECT
        wp_type AS dimension,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(wr_return_amt_inc_tax) AS sum_wr_return_amt_inc_tax,
        SUM(cr_net_loss + wr_net_loss) AS sum_total_net_loss
    FROM joined
    GROUP BY wp_type
),
combined AS (
    SELECT
        c_customer_id AS key1,
        cp_department AS key2,
        sum_cr_return_amount,
        sum_wr_return_amt_inc_tax,
        sum_total_net_loss,
        NULL AS dimension
    FROM agg_rollup
    UNION ALL
    SELECT
        NULL AS key1,
        NULL AS key2,
        sum_cr_return_amount,
        sum_wr_return_amt_inc_tax,
        sum_total_net_loss,
        dimension
    FROM agg_type
)
SELECT
    key1,
    key2,
    dimension,
    sum_cr_return_amount,
    sum_wr_return_amt_inc_tax,
    sum_total_net_loss,
    ROW_NUMBER() OVER (ORDER BY sum_total_net_loss DESC) AS rn
FROM combined
WHERE sum_total_net_loss IS NOT NULL
ORDER BY sum_total_net_loss DESC
LIMIT 100
