WITH catalog_ret AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            SUM(cr.cr_return_amount)               AS total_return_amount,
            SUM(cr.cr_net_loss)                    AS total_net_loss,
            CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
            d.d_date                               AS return_date,
            ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
        GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
    ),
    web_ret AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            SUM(wr.wr_return_amt)               AS total_return_amount,
            SUM(wr.wr_net_loss)                 AS total_net_loss,
            CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
            d.d_date                             AS return_date,
            ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
        GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
    )
SELECT *
FROM (
        SELECT
            'catalog' AS source,
            cr.c_customer_sk,
            cr.c_first_name,
            cr.c_last_name,
            cr.total_return_amount,
            cr.total_net_loss,
            cr.return_level,
            cr.return_date,
            cr.rn
        FROM catalog_ret cr
        WHERE NOT EXISTS (
                SELECT 1
                FROM catalog_sales cs
                WHERE cs.cs_bill_customer_sk = cr.c_customer_sk
                  AND cs.cs_sold_date_sk = (
                        SELECT d_date_sk
                        FROM date_dim
                        WHERE d_year = 2001
                        LIMIT 1
                    )
            )
        UNION ALL
        SELECT
            'web' AS source,
            wr.c_customer_sk,
            wr.c_first_name,
            wr.c_last_name,
            wr.total_return_amount,
            wr.total_net_loss,
            wr.return_level,
            wr.return_date,
            wr.rn
        FROM web_ret wr
        WHERE NOT EXISTS (
                SELECT 1
                FROM catalog_sales cs
                WHERE cs.cs_bill_customer_sk = wr.c_customer_sk
                  AND cs.cs_sold_date_sk = (
                        SELECT d_date_sk
                        FROM date_dim
                        WHERE d_year = 2001
                        LIMIT 1
                    )
            )
    ) combined
ORDER BY total_return_amount DESC
LIMIT 100
