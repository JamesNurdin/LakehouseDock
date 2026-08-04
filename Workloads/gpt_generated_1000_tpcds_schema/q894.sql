WITH
    sampled_sales AS (
        SELECT ss_customer_sk, ss_net_paid, ss_sold_time_sk
        FROM store_sales TABLESAMPLE BERNOULLI (10)
        WHERE ss_net_paid > 1000
    ),
    sales_join AS (
        SELECT
            ss.ss_customer_sk,
            c.c_first_name,
            c.c_last_name,
            t.t_hour,
            ss.ss_net_paid,
            CASE WHEN ss.ss_net_paid > 5000 THEN 'High' ELSE 'Medium' END AS payment_category
        FROM sampled_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    ),
    returns_join AS (
        SELECT
            cr.cr_returned_time_sk AS t_time_sk,
            cr.cr_refunded_customer_sk AS customer_sk,
            r.r_reason_desc,
            cr.cr_return_amount,
            CASE WHEN cr.cr_return_amount > 2000 THEN 'Large' ELSE 'Small' END AS return_size
        FROM catalog_returns cr
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    ),
    web_returns_join AS (
        SELECT
            wr.wr_returned_time_sk AS t_time_sk,
            wr.wr_refunded_customer_sk AS customer_sk,
            r.r_reason_desc,
            wr.wr_return_amt,
            CASE WHEN wr.wr_return_amt > 2000 THEN 'Large' ELSE 'Small' END AS return_size
        FROM web_returns wr
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    ),
    combined_returns AS (
        SELECT
            COALESCE(r.t_time_sk, w.t_time_sk) AS t_time_sk,
            COALESCE(r.customer_sk, w.customer_sk) AS customer_sk,
            COALESCE(r.r_reason_desc, w.r_reason_desc) AS reason_desc,
            COALESCE(r.cr_return_amount, w.wr_return_amt) AS return_amount,
            COALESCE(r.return_size, w.return_size) AS return_size
        FROM returns_join r
        FULL OUTER JOIN web_returns_join w
            ON r.t_time_sk = w.t_time_sk AND r.customer_sk = w.customer_sk
    ),
    ranked_returns AS (
        SELECT
            cr.t_time_sk,
            cr.customer_sk,
            cr.reason_desc,
            cr.return_amount,
            cr.return_size,
            ROW_NUMBER() OVER (PARTITION BY cr.customer_sk ORDER BY cr.return_amount DESC) AS return_rank
        FROM combined_returns cr
        WHERE cr.return_amount IS NOT NULL
    ),
    sales_customers AS (
        SELECT DISTINCT ss_customer_sk FROM store_sales
    ),
    return_customers AS (
        SELECT DISTINCT cr_refunded_customer_sk AS customer_sk FROM catalog_returns
        UNION
        SELECT DISTINCT wr_refunded_customer_sk FROM web_returns
    ),
    customers_without_returns AS (
        SELECT sc.ss_customer_sk
        FROM sales_customers sc
        EXCEPT
        SELECT rc.customer_sk FROM return_customers rc
    )
SELECT
    c.ss_customer_sk AS customer_sk,
    NULL AS reason_desc,
    NULL AS return_amount,
    NULL AS return_size,
    NULL AS return_rank,
    'NoReturn' AS category
FROM customers_without_returns c
UNION ALL
SELECT
    rr.customer_sk,
    rr.reason_desc,
    rr.return_amount,
    rr.return_size,
    rr.return_rank,
    'HasReturn' AS category
FROM ranked_returns rr
ORDER BY customer_sk, category
