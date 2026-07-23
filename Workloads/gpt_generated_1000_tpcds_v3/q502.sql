WITH filtered_pages AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_url
    FROM web_page wp
    WHERE wp.wp_type = 'ad'
      AND wp.wp_image_count >= 4
      AND wp.wp_access_date_sk = 2452601
)
SELECT
    fp.wp_web_page_sk,
    fp.wp_url,
    CASE WHEN fp.wp_image_count >= 5 THEN 'HighImage' ELSE 'LowImage' END AS image_category,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_ship_cost) AS avg_ship_cost,
    MIN(wr.wr_return_amt) AS min_return_amount,
    MAX(wr.wr_return_amt) AS max_return_amount,
    SUM(CASE WHEN wr.wr_return_amt_inc_tax > 500 THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS sum_large_returns_inc_tax
FROM filtered_pages fp
JOIN web_returns wr
    ON wr.wr_web_page_sk = fp.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_web_page_sk = fp.wp_web_page_sk
      AND wp2.wp_type = 'welcome'
)
  AND wr.wr_return_ship_cost > 500.00
  AND wr.wr_return_quantity > 1
GROUP BY
    fp.wp_web_page_sk,
    fp.wp_url,
    fp.wp_image_count
HAVING
    SUM(wr.wr_return_amt) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100
