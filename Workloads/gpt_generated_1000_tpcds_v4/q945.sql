WITH filtered_store_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_net_loss > 0
)
SELECT
    concat(s.s_store_name, ' - ', s.s_city)               AS store_location,
    substr(s.s_store_name, 1, 5)                         AS store_name_prefix,
    d.d_year,
    SUM(sr.sr_net_loss)                                 AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number)                 AS return_transactions
FROM filtered_store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
  AND c.c_first_name LIKE 'A%'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cr.cr_returned_date_sk = sr.sr_returned_date_sk
          AND regexp_like(cp.cp_description, '.*Special.*')
    )
GROUP BY
    s.s_store_name,
    s.s_city,
    d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
