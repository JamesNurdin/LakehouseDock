SELECT
    a.cr_order_number,
    a.d_year,
    a.d_month_seq,
    a.i_category,
    a.i_brand,
    a.s_state,
    a.s_city,
    a.wp_type,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_qty,
    a.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS rank_by_year
FROM (
    SELECT
        cr.cr_order_number,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_city,
        wp.wp_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk AND wp.wp_access_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year >= 2000
    GROUP BY
        cr.cr_order_number,
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_city,
        wp.wp_type
    HAVING SUM(cr.cr_return_amount) > 0
) a
ORDER BY a.total_return_amount DESC
LIMIT 100
