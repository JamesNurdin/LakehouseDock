WITH high_image_returns AS (
    SELECT
        wp.wp_web_page_id,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_image_count >= 5
      AND wr.wr_return_quantity > 1
      AND wr.wr_refunded_addr_sk IN (3648979, 541063)
    GROUP BY wp.wp_web_page_id
)
SELECT
    combined.wp_web_page_id,
    combined.total_return_amt,
    combined.return_cnt,
    combined.source
FROM (
    SELECT
        wp_web_page_id,
        total_return_amt,
        return_cnt,
        'high_image' AS source
    FROM high_image_returns

    UNION ALL

    SELECT
        wp.wp_web_page_id AS wp_web_page_id,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        'large_return' AS source
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'home'
      AND wr.wr_return_amt > 100
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY wp.wp_web_page_id
) AS combined
ORDER BY combined.total_return_amt DESC
LIMIT 100
