WITH store_ret AS (
    SELECT
        c.c_customer_id,
        s.s_store_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        sr.sr_return_amt,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY sr.sr_return_amt DESC) AS state_return_rank,
        REGEXP_EXTRACT(ca.ca_address_id, '([A-Z]+[0-9]+)', 1) AS extracted_addr_code
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(s.s_city, '^.*ville$')
      AND ca.ca_city LIKE 'S%'
),
web_ret AS (
    SELECT
        c.c_customer_id,
        wp.wp_web_page_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        wr.wr_return_amt,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY wr.wr_return_amt DESC) AS type_return_rank,
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1) AS extracted_domain
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com')
      AND ca.ca_city LIKE '%field'
)
SELECT intersected.c_customer_id
FROM (
    SELECT c_customer_id FROM store_ret WHERE state_return_rank = 1
    INTERSECT
    SELECT c_customer_id FROM web_ret WHERE type_return_rank = 1
) AS intersected
LIMIT 100
