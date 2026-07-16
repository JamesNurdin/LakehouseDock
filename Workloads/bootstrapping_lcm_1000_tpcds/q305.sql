WITH aggregated_returns AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_return_fee,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_store_credit) AS total_store_credit,
        MIN(d_creation.d_date) AS earliest_page_creation_date,
        MAX(d_access.d_date) AS latest_page_access_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wp.wp_access_date_sk = d_ret.d_date_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space
)
SELECT
    ar.d_year,
    ar.d_month_seq,
    ar.s_state,
    ar.s_store_name,
    ar.s_city,
    ar.total_return_amount,
    ar.avg_return_fee,
    ar.total_return_qty,
    ar.total_store_credit,
    ar.distinct_web_pages,
    DATE_DIFF('day', ar.earliest_page_creation_date, ar.latest_page_access_date) AS days_between_creation_and_access,
    ROUND(ar.total_return_qty * 1.0 / NULLIF(ar.s_floor_space, 0), 4) AS qty_per_floor_space,
    RANK() OVER (PARTITION BY ar.s_state ORDER BY ar.total_return_amount DESC) AS state_store_rank
FROM aggregated_returns ar
ORDER BY ar.total_return_amount DESC
LIMIT 100
