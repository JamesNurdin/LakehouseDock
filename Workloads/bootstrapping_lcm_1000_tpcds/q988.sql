WITH aggregated AS (
    SELECT
        d_return.d_date AS return_date,
        d_return.d_year,
        d_return.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_fee) AS total_catalog_fee,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(wr.wr_fee) AS total_web_fee,
        wp.wp_url,
        wp.wp_type,
        d_wp_creation.d_date AS wp_creation_date,
        d_wp_access.d_date AS wp_access_date,
        SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    INNER JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    INNER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    INNER JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    INNER JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    INNER JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    GROUP BY
        d_return.d_date,
        d_return.d_year,
        d_return.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        wp.wp_url,
        wp.wp_type,
        d_wp_creation.d_date,
        d_wp_access.d_date
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
