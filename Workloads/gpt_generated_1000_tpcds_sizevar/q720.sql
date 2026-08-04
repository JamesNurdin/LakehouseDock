WITH page_returns AS (
    SELECT
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns,
        MIN(wr.wr_return_quantity) AS min_qty,
        MAX(wr.wr_return_quantity) AS max_qty
    FROM web_returns wr
    WHERE wr.wr_returning_addr_sk = 4535762
      AND wr.wr_refunded_cash > 100
      AND wr.wr_return_quantity > 1
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY wr.wr_web_page_sk
)
SELECT
    wp.wp_web_page_id,
    wp.wp_type,
    pr.sum_return_amt,
    pr.avg_return_tax,
    pr.cnt_returns,
    wp.wp_max_ad_count,
    wp.wp_char_count,
    wp.wp_link_count,
    LAG(pr.sum_return_amt) OVER (ORDER BY pr.sum_return_amt DESC) AS lag_sum_return_amt,
    CASE WHEN EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
          AND wp2.wp_max_ad_count = 0
    ) THEN 1 ELSE 0 END AS has_zero_ad_page
FROM page_returns pr
JOIN web_page wp
    ON pr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_max_ad_count >= 2
  AND wp.wp_char_count BETWEEN 2000 AND 5000
  AND wp.wp_link_count >= 10
  AND wp.wp_type IN ('Home', 'Product')
ORDER BY pr.sum_return_amt DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
