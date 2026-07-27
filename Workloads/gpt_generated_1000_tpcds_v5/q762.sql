WITH base AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        c.c_salutation,
        ca.ca_state,
        d.d_year,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        t.t_hour,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND c.c_salutation = 'Mr.'
        AND ca.ca_state = 'CA'
        AND s.s_state = 'CA'
        AND r.r_reason_desc = 'Damaged'
        AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        c_salutation,
        ca_state,
        r_reason_desc,
        t_hour,
        wp_type,
        SUM(sr_return_amt) AS total_store_return_amount,
        AVG(wr_return_amt) AS avg_web_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS distinct_ticket_count,
        MIN(sr_return_quantity) AS min_return_qty,
        MAX(wr_return_quantity) AS max_web_return_qty
    FROM base
    GROUP BY
        s_store_name,
        d_year,
        c_salutation,
        ca_state,
        r_reason_desc,
        t_hour,
        wp_type
)
SELECT
    s_store_name,
    d_year,
    c_salutation,
    ca_state,
    r_reason_desc,
    t_hour,
    wp_type,
    total_store_return_amount,
    avg_web_return_amount,
    distinct_ticket_count,
    min_return_qty,
    max_web_return_qty,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_store_return_amount DESC) AS store_return_rank
FROM agg
ORDER BY total_store_return_amount DESC
LIMIT 100
