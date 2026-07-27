WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM tpcds.catalog_returns
),
returns_by_returning AS (
    SELECT
        cust.c_customer_id AS customer_id,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer cust
        ON cr.cr_returning_customer_sk = cust.c_customer_sk
    JOIN tpcds.warehouse wh
        ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    WHERE wh.w_zip = '44593'
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
    GROUP BY cust.c_customer_id
),
returns_by_refunded AS (
    SELECT
        cust.c_customer_id AS customer_id,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN tpcds.warehouse wh
        ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    WHERE wh.w_zip = '36098'
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = cust.c_customer_sk
            AND cr2.cr_return_amount > 0
      )
    GROUP BY cust.c_customer_id
)
SELECT DISTINCT
    customer_id,
    total_return_amount
FROM (
    SELECT customer_id, total_return_amount FROM returns_by_returning
    UNION ALL
    SELECT customer_id, total_return_amount FROM returns_by_refunded
) combined
ORDER BY total_return_amount DESC
LIMIT 100
