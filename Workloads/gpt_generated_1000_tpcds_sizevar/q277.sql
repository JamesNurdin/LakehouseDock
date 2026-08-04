WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_refunded_cash,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.d_year,
        split(c.c_email_address, '@') AS email_parts
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.*@.*\\.com$')
      AND c.c_first_name LIKE 'A%'
),
exploded AS (
    SELECT
        b.d_year,
        b.c_customer_id,
        b.c_first_name,
        b.c_last_name,
        b.c_email_address,
        ep.email_part,
        ep.part_pos,
        b.sr_refunded_cash
    FROM base b
    CROSS JOIN UNNEST(b.email_parts) WITH ORDINALITY AS ep(email_part, part_pos)
),
agg AS (
    SELECT
        d_year,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address,
        SUM(sr_refunded_cash) AS total_refunded,
        -- domain extracted by array position (part after '@')
        MAX(CASE WHEN part_pos = 2 THEN email_part END) AS email_domain,
        -- domain extracted by regexp for illustration
        regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS extracted_domain
    FROM exploded
    GROUP BY
        d_year,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address
)
SELECT
    d_year,
    c_customer_id,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    email_domain,
    extracted_domain,
    total_refunded,
    RANK() OVER (PARTITION BY d_year ORDER BY total_refunded DESC) AS revenue_rank
FROM agg
ORDER BY d_year DESC, total_refunded DESC
LIMIT 100
