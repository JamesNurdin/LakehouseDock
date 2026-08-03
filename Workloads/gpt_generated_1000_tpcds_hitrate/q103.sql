WITH store_losses AS (
    SELECT
        'Store' AS source_type,
        s.s_store_id AS location_id,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM
        store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_id
),
web_losses AS (
    SELECT
        'Web' AS source_type,
        wp.wp_web_page_id AS location_id,
        SUM(wr.wr_net_loss) AS total_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM
        web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY
        wp.wp_web_page_id
),
combined AS (
    SELECT * FROM store_losses
    UNION ALL
    SELECT * FROM web_losses
)
SELECT
    source_type,
    location_id,
    total_loss,
    loss_category,
    SUM(total_loss) OVER (PARTITION BY source_type ORDER BY total_loss DESC ROWS UNBOUNDED PRECEDING) AS running_total_loss
FROM
    combined
ORDER BY
    total_loss DESC
LIMIT 100
