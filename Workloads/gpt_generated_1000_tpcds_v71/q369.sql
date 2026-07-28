WITH filtered_returns AS (
    SELECT
        wr.wr_returning_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date < DATE '2002-01-01'
      AND regexp_like(wp.wp_url, '^https?://.*\\.com')
)
SELECT
    r.r_reason_id,
    regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_first_word,
    COUNT(DISTINCT fr.wr_order_number) AS distinct_orders,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_net_loss) AS avg_net_loss,
    CASE WHEN SUM(fr.wr_return_amt) > 500 THEN 'HighTotal' ELSE 'LowTotal' END AS total_category,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    (SELECT avg(wr2.wr_net_loss) FROM web_returns wr2) AS overall_avg_net_loss
FROM filtered_returns fr
JOIN reason r
    ON fr.wr_reason_sk = r.r_reason_sk
JOIN customer c
    ON fr.wr_returning_customer_sk = c.c_customer_sk
WHERE r.r_reason_desc LIKE '%purchase%'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr_ex
        JOIN reason r_ex ON wr_ex.wr_reason_sk = r_ex.r_reason_sk
        WHERE wr_ex.wr_returning_customer_sk = c.c_customer_sk
          AND r_ex.r_reason_desc LIKE '%duplicate%'
      )
GROUP BY
    r.r_reason_id,
    regexp_extract(r.r_reason_desc, '(\\w+)', 1),
    c.c_first_name,
    c.c_last_name
ORDER BY SUM(fr.wr_return_amt) DESC
LIMIT 100
