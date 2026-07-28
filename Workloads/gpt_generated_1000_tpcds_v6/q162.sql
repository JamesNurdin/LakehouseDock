/* goal: Compare return behavior of customers segmented by shipping date and birth month, categorizing net loss and counting total returns, then combine the two segments */
WITH q1 AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name  AS last_name,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = c.c_customer_sk) AS total_returns_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE c.c_first_shipto_date_sk > 2451000
      AND ca.ca_county = 'Washington County'
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE WHEN sr.sr_net_loss > 100 THEN 'High' ELSE 'Low' END,
        c.c_customer_sk
),
q2 AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name  AS last_name,
        CASE WHEN sr.sr_net_loss > 200 THEN 'Very High' ELSE 'Moderate' END AS loss_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = c.c_customer_sk) AS total_returns_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 7
      AND ca.ca_suite_number LIKE 'Suite %'
      AND EXISTS (
          SELECT 1 FROM store_returns sr3
          WHERE sr3.sr_customer_sk = c.c_customer_sk
            AND sr3.sr_return_quantity > 5
      )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE WHEN sr.sr_net_loss > 200 THEN 'Very High' ELSE 'Moderate' END,
        c.c_customer_sk
)
SELECT DISTINCT
    customer_id,
    first_name,
    last_name,
    loss_category,
    total_return_amount,
    total_returns_cnt
FROM (
    SELECT * FROM q1
    UNION ALL
    SELECT * FROM q2
) combined
ORDER BY total_return_amount DESC
LIMIT 100
