WITH
    store_ret_agg AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            SUM(sr.sr_net_loss) AS total_sr_net_loss,
            COUNT(*) AS sr_returns_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY sr.sr_customer_sk
    ),
    web_ret_agg AS (
        SELECT
            wr.wr_returning_customer_sk AS customer_sk,
            SUM(wr.wr_net_loss) AS total_wr_net_loss,
            COUNT(*) AS wr_returns_cnt
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY wr.wr_returning_customer_sk
    ),
    intersect_customers AS (
        SELECT customer_sk FROM store_ret_agg
        INTERSECT
        SELECT customer_sk FROM web_ret_agg
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain,
    (
        SELECT SUM(ss.ss_net_paid)
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE ss.ss_customer_sk = c.c_customer_sk
          AND d2.d_year = 2002
    ) AS total_store_sales_2002,
    sr.total_sr_net_loss,
    wr.total_wr_net_loss,
    sr.sr_returns_cnt,
    wr.wr_returns_cnt
FROM intersect_customers ic
JOIN customer c ON ic.customer_sk = c.c_customer_sk
JOIN store_ret_agg sr ON sr.customer_sk = ic.customer_sk
JOIN web_ret_agg wr ON wr.customer_sk = ic.customer_sk
WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
  AND c.c_last_name LIKE 'A%'
  AND substring(c.c_first_name, 1, 1) = 'J'
ORDER BY total_store_sales_2002 DESC
LIMIT 100
