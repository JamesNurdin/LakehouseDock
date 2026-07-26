SELECT
    wp.wp_web_page_id,
    wp.wp_url,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_return_customers,
    AVG(c.c_birth_year) AS avg_returning_customer_birth_year,
    CASE
        WHEN SUM(wr.wr_return_amt) > 10000 THEN 'High Return'
        WHEN SUM(wr.wr_return_amt) > 5000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    DENSE_RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS return_rank
FROM web_page wp
JOIN web_returns wr
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN customer c
    ON wr.wr_returning_customer_sk = c.c_customer_sk
GROUP BY wp.wp_web_page_id, wp.wp_url
ORDER BY return_rank
LIMIT 20
