WITH refunded_returns AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       cd.cd_credit_rating,
       wr.wr_return_amt,
       r.r_reason_desc
   FROM web_returns wr
   FULL OUTER JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_return_amt > 0
),
high_estimate_customers AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       cd.cd_credit_rating,
       cd.cd_purchase_estimate
   FROM customer c
   JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_purchase_estimate >= 7000
     AND EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
     )
)
SELECT
    fr.c_customer_sk AS customer_sk,
    fr.c_first_name AS first_name,
    fr.c_last_name AS last_name,
    fr.cd_credit_rating AS credit_rating,
    fr.wr_return_amt AS amount
FROM refunded_returns fr

UNION

SELECT
    he.c_customer_sk,
    he.c_first_name,
    he.c_last_name,
    he.cd_credit_rating,
    CAST(he.cd_purchase_estimate AS decimal(10,2)) AS amount
FROM high_estimate_customers he

EXCEPT

SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_credit_rating,
    CAST(0 AS decimal(10,2)) AS amount
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      AND r.r_reason_id = 'AAAAAAADAAAAAAA'
)
ORDER BY credit_rating DESC, amount DESC
LIMIT 100
