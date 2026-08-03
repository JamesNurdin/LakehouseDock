WITH RECURSIVE date_range (cur_date) AS (
    SELECT DATE '2022-01-01'
    UNION ALL
    SELECT cur_date + INTERVAL '1' DAY
    FROM date_range
    WHERE cur_date + INTERVAL '1' DAY <= DATE '2022-01-31'
)
SELECT
    s.s_store_id,
    CONCAT(s.s_street_name, ', ', s.s_city, ', ', s.s_state) AS full_address,
    REGEXP_EXTRACT(s.s_street_name, '(\\w+)') AS first_street_word,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_return_customers,
    (
        SELECT COUNT(DISTINCT c.c_customer_sk)
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_zip = s.s_zip
    ) AS customers_in_zip,
    street_word
FROM
    store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN date_range dr ON d.d_date = dr.cur_date
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        AND r.r_reason_desc LIKE '%damaged%'
    CROSS JOIN UNNEST(split(s.s_street_name, ' ')) AS t(street_word)
WHERE
    REGEXP_LIKE(s.s_street_name, '^S')
    AND s.s_street_name LIKE '%Park%'
GROUP BY
    s.s_store_id,
    s.s_street_name,
    s.s_city,
    s.s_state,
    street_word,
    s.s_zip
ORDER BY
    total_net_paid DESC
LIMIT 100
