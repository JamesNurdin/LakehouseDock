WITH returns_dates AS (
        SELECT DISTINCT cr.cr_returned_date_sk AS date_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    sales_dates AS (
        SELECT DISTINCT ws.ws_sold_date_sk AS date_sk
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    high_return_dates AS (
        SELECT cr.cr_returned_date_sk AS date_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_return_amount > 500
          AND d.d_year = 2001
    ),
    target_dates AS (
        SELECT date_sk
        FROM returns_dates
        INTERSECT
        SELECT date_sk
        FROM sales_dates
        EXCEPT
        SELECT date_sk
        FROM high_return_dates
    ),
    return_agg AS (
        SELECT cr.cr_returned_date_sk AS date_sk,
               SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY cr.cr_returned_date_sk
    ),
    sales_agg AS (
        SELECT ws.ws_sold_date_sk AS date_sk,
               SUM(ws.ws_net_paid) AS total_sales_amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY ws.ws_sold_date_sk
    )
SELECT
    d.d_date AS date,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    -- Running total of sales amount ordered by date
    SUM(COALESCE(s.total_sales_amount, 0)) OVER (ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS running_sales_amount,
    -- Correlated scalar subquery: distinct customers that bought in stores on the same date
    (SELECT COUNT(DISTINCT ss.ss_customer_sk)
     FROM store_sales ss
     WHERE ss.ss_sold_date_sk = d.d_date_sk) AS distinct_store_customers
FROM target_dates td
JOIN date_dim d ON td.date_sk = d.d_date_sk
LEFT JOIN return_agg r ON d.d_date_sk = r.date_sk
LEFT JOIN sales_agg s ON d.d_date_sk = s.date_sk
ORDER BY d.d_date
LIMIT 100
