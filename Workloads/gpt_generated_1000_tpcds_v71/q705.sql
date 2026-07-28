WITH page_returns AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_image_count,
        wp.wp_rec_end_date,
        COUNT(wr.wr_order_number) AS returns_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash
    FROM tpcds.web_page wp
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND wp.wp_image_count >= 3
      AND wp.wp_type IS NOT NULL
      AND wp.wp_url LIKE '%example%'
    GROUP BY
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_image_count,
        wp.wp_rec_end_date
)
SELECT
    pr.wp_web_page_id,
    pr.wp_image_count,
    pr.returns_cnt,
    pr.total_return_inc_tax,
    pr.total_refunded_cash,
    CASE WHEN pr.total_return_inc_tax = 0 THEN 0
         ELSE pr.total_refunded_cash / pr.total_return_inc_tax END AS cash_to_return_ratio,
    (SELECT AVG(total_return_inc_tax) FROM page_returns) AS avg_total_return_inc_tax
FROM page_returns pr
WHERE pr.total_return_inc_tax > (SELECT AVG(total_return_inc_tax) FROM page_returns)
  AND pr.returns_cnt > 5
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_web_page_sk = pr.wp_web_page_sk
          AND wr2.wr_refunded_cash > 500
    )
ORDER BY pr.total_return_inc_tax DESC
LIMIT 100
