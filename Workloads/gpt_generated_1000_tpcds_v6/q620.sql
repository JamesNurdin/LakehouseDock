/* goal: Identify high‑value customers who received refunds on web pages of type 'Content' within a specific period, summarizing their return amounts and ranking them per customer */
WITH returns_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        wr_web_page_sk AS web_page_sk,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt) AS avg_return_amt,
        COUNT(*) AS cnt_returns,
        MIN(wr_return_amt) AS min_return_amt,
        MAX(wr_return_amt) AS max_return_amt
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_return_quantity >= 1
      AND wr_returned_date_sk BETWEEN 2450000 AND 2453000
    GROUP BY wr_refunded_customer_sk, wr_web_page_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    wp.wp_url,
    wp.wp_type,
    ra.total_return_amt,
    ra.avg_return_amt,
    ra.cnt_returns,
    ra.min_return_amt,
    ra.max_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ra.total_return_amt DESC) AS rn
FROM returns_agg ra
JOIN customer c
  ON c.c_customer_sk = ra.customer_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = ra.web_page_sk
WHERE c.c_birth_year = 1975
  AND c.c_preferred_cust_flag = 'Y'
  AND wp.wp_rec_end_date = DATE '2000-09-02'
  AND wp.wp_link_count >= 20
  AND EXISTS (
        SELECT 1
        FROM web_page wp_sub
        WHERE wp_sub.wp_web_page_sk = ra.web_page_sk
          AND wp_sub.wp_type = 'Content'
    )
ORDER BY ra.total_return_amt DESC, rn
LIMIT 100
