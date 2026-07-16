WITH aggregated AS (
    SELECT
        d_ret.d_year,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        MIN(d_creation.d_date) AS first_page_creation_date,
        MAX(d_access.d_date) AS last_page_access_date,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_quantity,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wp.wp_char_count) AS avg_page_char_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_count
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_floor_space
)
SELECT
    a.d_year,
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.s_floor_space,
    a.first_page_creation_date,
    a.last_page_access_date,
    a.total_return_amount,
    a.total_return_quantity,
    a.avg_inventory_quantity,
    a.total_fee,
    a.avg_page_char_count,
    a.distinct_page_count,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS return_rank
FROM aggregated a
ORDER BY a.d_year, return_rank
LIMIT 100
