WITH aggregated AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month,
        d_end.d_year AS end_year,
        d_end.d_month_seq AS end_month,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        s.s_store_name AS closed_store_name,
        s.s_city AS closed_store_city,
        COUNT(*) AS return_events,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(i.i_current_price) AS avg_item_price,
        MIN(i.i_wholesale_cost) AS min_wholesale_cost,
        MAX(i.i_wholesale_cost) AS max_wholesale_cost,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        d_start.d_year,
        d_start.d_month_seq,
        d_end.d_year,
        d_end.d_month_seq,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city
)
SELECT
    cp_catalog_page_id,
    cp_description,
    cp_type,
    start_year,
    start_month,
    end_year,
    end_month,
    return_year,
    return_month,
    closed_store_name,
    closed_store_city,
    return_events,
    total_return_amount,
    total_return_quantity,
    avg_item_price,
    min_wholesale_cost,
    max_wholesale_cost,
    distinct_items,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
