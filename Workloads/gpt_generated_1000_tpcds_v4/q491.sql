WITH filtered_returns AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_refunded_cash
    FROM store_returns sr
    WHERE sr.sr_item_sk IN (138335, 118185)
      AND sr.sr_return_amt > 50
      AND sr.sr_refunded_cash BETWEEN 50 AND 200
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COUNT(*) AS return_cnt,
    SUM(fr.sr_refunded_cash) AS total_refunded_cash,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    MIN(fr.sr_return_quantity) AS min_return_qty,
    MAX(fr.sr_return_quantity) AS max_return_qty,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
    ) AS total_returns_by_customer
FROM filtered_returns fr
JOIN customer c
    ON fr.sr_customer_sk = c.c_customer_sk
JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND t.t_am_pm = 'PM'
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_last_review_date > 2452600
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_last_review_date
ORDER BY total_refunded_cash DESC
LIMIT 100
