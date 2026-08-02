WITH ticket_numbers_desc AS (
    SELECT ss.ss_ticket_number
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
),

 ticket_numbers_customer AS (
    SELECT ss.ss_ticket_number
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_first_name LIKE 'A%'
),

 intersect_tickets AS (
    SELECT ss_ticket_number FROM ticket_numbers_desc
    INTERSECT
    SELECT ss_ticket_number FROM ticket_numbers_customer
)
SELECT
    d.d_date,
    CONCAT(i.i_brand, ' - ', i.i_item_desc) AS brand_item,
    i.i_brand,
    regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_digits,
    COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales
FROM store_sales ss
RIGHT OUTER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE
    ss.ss_ticket_number IN (SELECT ss_ticket_number FROM intersect_tickets)
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
    )
    AND i.i_brand LIKE 'Brand%'
GROUP BY
    d.d_date,
    i.i_brand,
    i.i_item_desc,
    regexp_extract(i.i_item_desc, '(\\d{3})', 1)
ORDER BY total_sales DESC
LIMIT 100
