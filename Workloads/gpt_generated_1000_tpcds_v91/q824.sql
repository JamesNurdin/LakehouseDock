/*
Goal: Identify the top 100 customer demographic groups (gender, education) and address locations in 2020 that have the highest total net loss from store returns, 
where the sale address city starts with 'San' and the street name contains 'Poplar'. The query excludes returns with reasons mentioning 'Damaged' (anti‑join), 
filters to tickets with large return quantities, only keeps groups whose total net loss exceeds the overall 2020 average net loss, and showcases string processing via REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT, and SUBSTRING. It also uses DISTINCT (COUNT(DISTINCT)), subqueries (IN, scalar, NOT EXISTS), aggregation, and pagination.
*/
SELECT
    cd.cd_gender,
    cd.cd_education_status,
    SUBSTRING(cd.cd_credit_rating FROM 1 FOR 5) AS credit_rating_prefix,
    CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
    REGEXP_EXTRACT(r.r_reason_desc, '(?i)(defective|lost)', 1) AS extracted_reason,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT s.ss_ticket_number) AS distinct_tickets
FROM
    store_sales s
JOIN
    store_returns sr
        ON s.ss_ticket_number = sr.sr_ticket_number
JOIN
    date_dim d
        ON s.ss_sold_date_sk = d.d_date_sk
JOIN
    customer_demographics cd
        ON s.ss_cdemo_sk = cd.cd_demo_sk
JOIN
    customer_address ca
        ON s.ss_addr_sk = ca.ca_address_sk
JOIN
    reason r
        ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    d.d_year = 2020
    AND ca.ca_city LIKE 'San%'
    AND REGEXP_LIKE(ca.ca_street_name, '(?i)poplar')
    AND s.ss_ticket_number IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 5
    )
    AND NOT EXISTS (
        SELECT 1
        FROM reason r_ex
        WHERE r_ex.r_reason_sk = sr.sr_reason_sk
          AND REGEXP_LIKE(r_ex.r_reason_desc, '(?i)damaged')
    )
GROUP BY
    cd.cd_gender,
    cd.cd_education_status,
    SUBSTRING(cd.cd_credit_rating FROM 1 FOR 5),
    CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state),
    REGEXP_EXTRACT(r.r_reason_desc, '(?i)(defective|lost)', 1)
HAVING
    SUM(sr.sr_net_loss) > (
        SELECT AVG(sr2.sr_net_loss)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2020
    )
ORDER BY
    total_net_loss DESC
OFFSET 0
LIMIT 100
