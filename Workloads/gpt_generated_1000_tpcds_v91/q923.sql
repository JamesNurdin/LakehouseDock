WITH
    sales_tickets AS (
        SELECT ss.ss_ticket_number
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '(?i)shoe')
    ),
    non_returned_tickets AS (
        SELECT ss_ticket_number
        FROM sales_tickets
        EXCEPT
        SELECT sr_ticket_number
        FROM store_returns
    ),
    sales_filtered AS (
        SELECT ss.*
        FROM store_sales ss
        JOIN non_returned_tickets nrt ON ss.ss_ticket_number = nrt.ss_ticket_number
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE lower(i.i_item_desc) LIKE '%shoe%'
    )
SELECT
    s.s_store_name,
    d.d_year,
    MIN(l.city_prefix) AS city_prefix,
    MIN(l.store_full_address) AS store_full_address,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM sales_filtered ss
CROSS JOIN LATERAL (
        SELECT s.s_store_name,
               s.s_city,
               s.s_state,
               s.s_street_number,
               s.s_street_name,
               s.s_zip
        FROM store s
        WHERE s.s_store_sk = ss.ss_store_sk
) AS s
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
        SELECT regexp_extract(s.s_city, '^([A-Za-z]+)', 1) AS city_prefix,
               concat(s.s_street_number, ' ', s.s_street_name, ', ', s.s_city, ', ', s.s_state, ' ', s.s_zip) AS store_full_address
) AS l
WHERE lower(s.s_city) LIKE '%ville%'
GROUP BY ROLLUP (s.s_store_name, d.d_year)
ORDER BY s.s_store_name, d.d_year
LIMIT 100
