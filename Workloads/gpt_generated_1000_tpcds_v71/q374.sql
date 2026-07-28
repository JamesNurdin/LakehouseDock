WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        c.c_customer_id,
        ca.ca_city,
        t.t_hour,
        wp.wp_url
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_current_price > 20
),
aggregated AS (
    SELECT
        d_year,
        s_state,
        i_category,
        r_reason_desc,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_qty
    FROM joined_data
    GROUP BY GROUPING SETS (
        (d_year, s_state, i_category, r_reason_desc),
        (d_year, s_state, i_category),
        (d_year, s_state),
        (d_year)
    )
)
SELECT
    d_year,
    s_state,
    i_category,
    r_reason_desc,
    total_return_amount,
    total_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_by_amount,
    SUM(total_return_amount) OVER (PARTITION BY d_year) AS year_total_return_amount
FROM aggregated
ORDER BY d_year, s_state, total_return_amount DESC
LIMIT 100
