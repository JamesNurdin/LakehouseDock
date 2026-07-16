WITH aggregated AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wp.wp_type AS page_type,
        dr.d_year AS return_year,
        da.d_year AS access_year,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        MIN(dr.d_date) AS earliest_return_date,
        MAX(dr.d_date) AS latest_return_date
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dr.d_date_sk
    JOIN date_dim da ON wp.wp_access_date_sk = da.d_date_sk
    WHERE dr.d_year BETWEEN 2015 AND 2020
      AND s.s_state IS NOT NULL
    GROUP BY
        r.r_reason_desc,
        s.s_city,
        s.s_state,
        wp.wp_type,
        dr.d_year,
        da.d_year,
        dr.d_date,
        da.d_date
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    reason_desc,
    store_city,
    store_state,
    page_type,
    return_year,
    access_year,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_ship_cost,
    distinct_web_pages,
    earliest_return_date,
    latest_return_date,
    ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY total_net_loss DESC) AS loss_rank_by_reason
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
