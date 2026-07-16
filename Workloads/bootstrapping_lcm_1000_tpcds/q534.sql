WITH agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_description,
        s.s_store_id,
        s.s_city,
        dd_start.d_year AS start_year,
        dd_start.d_month_seq AS start_month,
        dd_end.d_year AS end_year,
        dd_end.d_month_seq AS end_month,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT wp_create.wp_web_page_id) AS num_created_pages,
        COUNT(DISTINCT wp_access.wp_web_page_id) AS num_accessed_pages
    FROM catalog_page cp
    JOIN date_dim dd_start
        ON cp.cp_start_date_sk = dd_start.d_date_sk
    JOIN date_dim dd_end
        ON cp.cp_end_date_sk = dd_end.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = dd_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = dd_end.d_date_sk
    JOIN web_page wp_create
        ON wp_create.wp_creation_date_sk = dd_start.d_date_sk
    JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = dd_end.d_date_sk
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_description,
        s.s_store_id,
        s.s_city,
        dd_start.d_year,
        dd_start.d_month_seq,
        dd_end.d_year,
        dd_end.d_month_seq
)
SELECT
    agg.cp_catalog_page_id,
    agg.cp_department,
    agg.cp_description,
    agg.s_store_id,
    agg.s_city,
    agg.start_year,
    agg.start_month,
    agg.end_year,
    agg.end_month,
    agg.total_qty,
    agg.num_created_pages,
    agg.num_accessed_pages,
    ROW_NUMBER() OVER (PARTITION BY agg.cp_department ORDER BY agg.total_qty DESC) AS dept_qty_rank
FROM agg
ORDER BY agg.total_qty DESC
LIMIT 100
