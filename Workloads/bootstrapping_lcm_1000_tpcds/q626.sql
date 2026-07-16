WITH aggregated AS (
    SELECT 
        ca.ca_state AS ca_state,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_return.d_year AS d_year,
        d_return.d_quarter_seq AS d_quarter_seq,
        d_return.d_date AS d_date,
        d_closed.d_year AS store_closed_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        MAX(wp.wp_image_count) AS max_images_per_page,
        SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_cnt
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_return.d_date_sk
    WHERE d_return.d_year = 2002
      AND s.s_state = ca.ca_state
    GROUP BY 
        ca.ca_state,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_return.d_year,
        d_return.d_quarter_seq,
        d_return.d_date,
        d_closed.d_year
)
SELECT
    ca_state,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_quarter_seq,
    d_date,
    store_closed_year,
    total_return_amt,
    avg_return_qty,
    distinct_tickets,
    pages_created,
    max_images_per_page,
    landing_page_cnt,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amt DESC) AS state_store_rank
FROM aggregated
WHERE total_return_amt > 1000
ORDER BY total_return_amt DESC
LIMIT 100
