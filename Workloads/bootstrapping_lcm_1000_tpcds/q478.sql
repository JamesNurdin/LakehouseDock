WITH aggregated AS (
    SELECT
        d_date.d_year,
        d_date.d_month_seq,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_quantity,
        MAX(wp.wp_image_count) AS max_image_count,
        MIN(wp.wp_link_count) AS min_link_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        AVG(DATE_DIFF('day', d_date.d_date, d_access.d_date)) AS avg_days_between_creation_access,
        AVG(DATE_DIFF('day', d_date.d_date, d_closed.d_date)) AS avg_days_until_store_closure
    FROM store_returns sr
    JOIN date_dim d_date
        ON sr.sr_returned_date_sk = d_date.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_date.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_date.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_date.d_year BETWEEN 2020 AND 2022
      AND s.s_state IN ('CA', 'TX')
    GROUP BY d_date.d_year, d_date.d_month_seq, s.s_store_name, s.s_state
    HAVING SUM(sr.sr_return_amt) > 10000
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    s_state,
    distinct_tickets,
    total_return_amount,
    total_return_quantity,
    avg_inventory_quantity,
    max_image_count,
    min_link_count,
    distinct_pages,
    avg_days_between_creation_access,
    avg_days_until_store_closure,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS yearly_return_rank
FROM aggregated
ORDER BY d_year, yearly_return_rank
LIMIT 100
