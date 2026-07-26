WITH page_metrics AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_max_ad_count,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amt_inc_tax,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS unique_orders,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_page wp
    LEFT JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_type, wp.wp_image_count, wp.wp_max_ad_count
)
SELECT
    pm.wp_web_page_sk,
    pm.wp_url,
    pm.wp_type,
    pm.wp_image_count,
    pm.wp_max_ad_count,
    pm.total_return_amt_inc_tax,
    pm.total_net_loss,
    pm.unique_orders,
    pm.avg_return_qty,
    ROW_NUMBER() OVER (ORDER BY pm.total_net_loss DESC) AS loss_rank,
    CASE
        WHEN pm.wp_image_count > 50 THEN 'IMAGE_RICH'
        WHEN pm.wp_max_ad_count > 20 THEN 'AD_RICH'
        ELSE 'NORMAL'
    END AS page_category,
    CASE
        WHEN pm.total_net_loss > 10000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_flag
FROM page_metrics pm
WHERE pm.total_net_loss > 0
ORDER BY loss_rank
LIMIT 5
