SELECT
    a.d_date,
    a.d_year,
    a.d_month_seq,
    a.num_returns,
    a.total_net_loss,
    a.avg_return_amount,
    a.total_fee,
    a.num_stores_closed,
    a.total_floor_space_closed,
    a.num_web_pages_created,
    a.total_link_count,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
        SUM(s.s_floor_space) AS total_floor_space_closed,
        COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages_created,
        SUM(wp.wp_link_count) AS total_link_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, d.d_year, d.d_month_seq
) a
ORDER BY a.total_net_loss DESC
LIMIT 100
