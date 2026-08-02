WITH
    filtered_customers AS (
        SELECT c_customer_sk
        FROM customer
        WHERE c_salutation = 'Mr.'
          AND c_current_addr_sk IN (2327291, 5257560)
        EXCEPT
        SELECT DISTINCT wr_refunded_customer_sk
        FROM web_returns
        WHERE wr_return_amt > 2000
    ),
    joined AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_return_ship_cost,
            wr.wr_refunded_customer_sk,
            wr.wr_returning_customer_sk,
            c_refunded.c_salutation AS refunded_salutation,
            c_refunded.c_birth_day,
            c_refunded.c_birth_month AS birth_month,
            c_returning.c_salutation AS returning_salutation
        FROM web_returns wr
        JOIN customer c_refunded
            ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
        JOIN customer c_returning
            ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
        WHERE c_refunded.c_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
          AND c_refunded.c_salutation = 'Mr.'
          AND c_refunded.c_birth_day IN (16, 30)
          AND c_refunded.c_birth_month = 5
          AND c_returning.c_salutation = 'Ms.'
          AND wr.wr_item_sk IN (81038, 200329)
          AND wr.wr_return_ship_cost > 200.0
          AND wr.wr_return_amt BETWEEN 100 AND 5000
          AND NOT EXISTS (
                SELECT 1
                FROM web_returns wr2
                WHERE wr2.wr_item_sk = wr.wr_item_sk
                  AND wr2.wr_return_quantity > 10
          )
    )
SELECT
    refunded_salutation,
    birth_month,
    CASE WHEN wr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_amt) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    MAX(wr_return_ship_cost) AS max_ship_cost,
    MIN(wr_return_ship_cost) AS min_ship_cost
FROM joined
GROUP BY
    refunded_salutation,
    birth_month,
    CASE WHEN wr_return_amt > 1000 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amount DESC
LIMIT 100
