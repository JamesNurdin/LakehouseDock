WITH page_return_agg AS (
    SELECT
        wp.wp_type,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM web_page wp
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_max_ad_count BETWEEN 1 AND 3
        AND wp.wp_image_count >= 2
        AND wr.wr_return_quantity > 0
        AND wr.wr_return_amt > 50
        AND wr.wr_return_ship_cost BETWEEN 50 AND 2000
        AND wp.wp_type IS NOT NULL
    GROUP BY
        wp.wp_type,
        wp.wp_max_ad_count,
        wp.wp_image_count
)
SELECT DISTINCT
    pra.wp_type,
    pra.distinct_pages,
    pra.total_return_amt,
    pra.avg_ship_cost,
    pra.total_net_loss,
    pra.total_returns,
    RANK() OVER (ORDER BY pra.total_net_loss DESC) AS net_loss_rank,
    pra.total_returns * 100.0 / (SELECT SUM(total_returns) FROM page_return_agg) AS pct_of_total_returns
FROM page_return_agg pra
WHERE pra.total_net_loss > (
    SELECT AVG(total_net_loss) FROM page_return_agg
)
ORDER BY net_loss_rank ASC
