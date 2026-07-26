WITH catalog_per_day AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        cr_returned_date_sk AS return_date_sk,
        SUM(cr_return_quantity) AS catalog_return_qty,
        SUM(cr_return_amount) AS catalog_return_amount
    FROM catalog_returns
    GROUP BY cr_refunded_customer_sk, cr_returned_date_sk
),
 web_per_day AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        wr_returned_date_sk AS return_date_sk,
        SUM(wr_return_quantity) AS web_return_qty,
        SUM(wr_return_amt) AS web_return_amount
    FROM web_returns
    GROUP BY wr_refunded_customer_sk, wr_returned_date_sk
),
 combined AS (
    SELECT
        cpd.customer_sk,
        cpd.return_date_sk,
        cpd.catalog_return_qty,
        wpd.web_return_qty,
        cpd.catalog_return_amount,
        wpd.web_return_amount,
        (cpd.catalog_return_qty + wpd.web_return_qty) AS total_return_qty,
        (cpd.catalog_return_amount + wpd.web_return_amount) AS total_return_amount
    FROM catalog_per_day cpd
    INNER JOIN web_per_day wpd
        ON cpd.customer_sk = wpd.customer_sk
        AND cpd.return_date_sk = wpd.return_date_sk
)
SELECT
    RANK() OVER (ORDER BY total_return_qty DESC) AS rank,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    comb.return_date_sk,
    comb.total_return_qty,
    comb.total_return_amount,
    CASE
        WHEN comb.total_return_amount > 5000 THEN 'HighValue'
        WHEN comb.total_return_amount BETWEEN 1000 AND 5000 THEN 'MediumValue'
        ELSE 'LowValue'
    END AS value_category
FROM combined comb
JOIN customer c
    ON comb.customer_sk = c.c_customer_sk
WHERE comb.total_return_qty > 0
ORDER BY rank
LIMIT 15
