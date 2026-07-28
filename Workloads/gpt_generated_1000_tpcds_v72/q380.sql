WITH sales_cte AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_address_id,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        CASE WHEN REGEXP_LIKE(ca.ca_address_id, '^A{8}') THEN 1 ELSE 0 END AS premium_addr_flag
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'A%'
      AND REGEXP_LIKE(ca.ca_address_id, '^A{8}')
)
SELECT
    s.city_state,
    s.ca_state,
    SUM(s.ss_net_paid) AS total_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    COUNT(DISTINCT s.ss_ticket_number) AS sales_txn_cnt,
    SUM(s.premium_addr_flag) AS premium_addr_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY SUM(s.ss_net_paid) DESC) AS rn_state,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_returning_addr_sk = s.ca_address_sk
          AND wr.wr_order_number = s.ss_ticket_number
          AND wr.wr_account_credit > 200
    ) AS high_credit_return_cnt
FROM sales_cte s
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = s.ca_address_sk
GROUP BY
    s.city_state,
    s.ca_state,
    s.ca_address_sk,
    s.ss_ticket_number
HAVING SUM(s.ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
