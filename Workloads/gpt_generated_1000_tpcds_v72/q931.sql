WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_list_price) AS avg_list_price,
        COUNT(*) AS sales_cnt
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_list_price > 30
      AND c.c_birth_year BETWEEN 1965 AND 1985
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.sales_cnt,
    COUNT(wr.wr_reason_sk) AS return_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    MIN(wr.wr_return_amt) AS min_return_amt,
    MAX(wr.wr_return_amt) AS max_return_amt
FROM customer_sales cs
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_customer_sk = cs.c_customer_sk
JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE wr.wr_return_quantity <= 5
  AND wr.wr_net_loss > 200
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY cs.c_customer_id, cs.c_first_name, cs.c_last_name, cs.total_sales, cs.sales_cnt
HAVING COUNT(wr.wr_reason_sk) >= 1
ORDER BY cs.total_sales DESC
LIMIT 100
