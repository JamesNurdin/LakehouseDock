WITH aggregated AS (
    SELECT
        d_ret.d_year,
        d_ret.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        ws.web_site_id,
        ws.web_name,
        ws.web_market_manager,
        wp.wp_url,
        wp.wp_type,
        d_ws_close.d_date AS site_close_date,
        d_page_access.d_date AS page_last_access_date,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS total_returns,
        SUM(wp.wp_image_count) AS total_images
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    WHERE cr.cr_net_loss > 0
    GROUP BY
        d_ret.d_year,
        d_ret.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        ws.web_site_id,
        ws.web_name,
        ws.web_market_manager,
        wp.wp_url,
        wp.wp_type,
        d_ws_close.d_date,
        d_page_access.d_date
)
SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_loss DESC) AS store_loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
