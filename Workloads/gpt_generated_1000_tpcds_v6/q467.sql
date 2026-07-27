WITH agg_returns AS (
    SELECT
        wr_returning_customer_sk,
        wr_web_page_sk,
        COUNT(*) AS cnt_returns,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt) AS avg_return_amt,
        SUM(wr_net_loss) AS total_net_loss
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt > 10
      AND wr_reversed_charge < 300
      AND wr_returned_date_sk BETWEEN 2450000 AND 2453000
      AND wr_reason_sk IN (1, 2, 3)
    GROUP BY wr_returning_customer_sk, wr_web_page_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_link_count,
    ar.cnt_returns,
    ar.total_return_amt,
    ar.avg_return_amt,
    ar.total_net_loss,
    (
        SELECT MAX(wr_return_amt)
        FROM web_returns
        WHERE wr_returning_customer_sk = c.c_customer_sk
    ) AS max_return_amt
FROM agg_returns ar
JOIN customer c
  ON ar.wr_returning_customer_sk = c.c_customer_sk
JOIN web_page wp
  ON ar.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'CHILE'
  AND c.c_first_sales_date_sk > 2452000
  AND wp.wp_type = 'Content'
  AND wp.wp_link_count BETWEEN 5 AND 20
  AND wp.wp_char_count > 1000
ORDER BY ar.total_return_amt DESC
LIMIT 100
