WITH aggregated AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        d_closed.d_date AS store_closed_date,
        d_closed.d_weekend AS store_closed_weekend,
        ws.web_name,
        ws.web_state,
        ws.web_tax_percentage,
        d_close.d_date AS site_close_date,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_char_count,
        d_access.d_date AS page_access_date
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_closed.d_date,
        d_closed.d_weekend,
        ws.web_name,
        ws.web_state,
        ws.web_tax_percentage,
        d_close.d_date,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_char_count,
        d_access.d_date
)
SELECT
    return_date,
    d_year,
    d_month_seq,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    total_return_amount,
    total_return_quantity,
    avg_return_tax,
    store_closed_date,
    store_closed_weekend,
    web_name,
    web_state,
    web_tax_percentage,
    site_close_date,
    wp_image_count,
    wp_link_count,
    wp_char_count,
    page_access_date,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS yearly_store_return_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
