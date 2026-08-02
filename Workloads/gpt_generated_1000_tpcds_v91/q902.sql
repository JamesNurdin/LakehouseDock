WITH page_return_agg AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        COUNT(wr.wr_return_quantity) AS return_count,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        CASE
            WHEN SUM(wr.wr_return_amt_inc_tax) >= 2000 THEN 'high'
            WHEN SUM(wr.wr_return_amt_inc_tax) >= 1000 THEN 'medium'
            ELSE 'low'
        END AS return_amount_category
    FROM web_page wp
    LEFT JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_max_ad_count > 0
        AND wp.wp_image_count >= 2
        AND wp.wp_type = 'home'
    GROUP BY
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_max_ad_count,
        wp.wp_image_count
),
high_return_pages AS (
    SELECT wp_web_page_sk
    FROM page_return_agg
    WHERE total_return_qty > 10
),
medium_return_pages AS (
    SELECT wp_web_page_sk
    FROM page_return_agg
    WHERE wp_max_ad_count >= 2
),
common_pages AS (
    SELECT wp_web_page_sk FROM high_return_pages
    INTERSECT
    SELECT wp_web_page_sk FROM medium_return_pages
)
SELECT
    pra.return_amount_category,
    COUNT(*) AS page_cnt,
    AVG(pra.total_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    SUM(pra.total_return_qty) AS sum_return_qty
FROM page_return_agg pra
JOIN common_pages cp
    ON pra.wp_web_page_sk = cp.wp_web_page_sk
GROUP BY pra.return_amount_category
ORDER BY avg_return_amt_inc_tax DESC
LIMIT 100
