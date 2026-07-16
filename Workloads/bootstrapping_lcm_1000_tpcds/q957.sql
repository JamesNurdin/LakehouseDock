WITH page_promo_stats AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_department,
        d_start.d_date AS page_start_date,
        d_end.d_date AS page_end_date,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.i_wholesale_cost) AS avg_item_wholesale_cost,
        COUNT(DISTINCT s.s_store_id) AS stores_closed_on_start
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d_start.d_date_sk
    WHERE cp.cp_type = 'Seasonal'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_department,
        d_start.d_date,
        d_end.d_date
)
SELECT
    pp.cp_catalog_page_id,
    pp.cp_catalog_page_number,
    pp.cp_department,
    pp.page_start_date,
    pp.page_end_date,
    pp.promo_count,
    pp.total_promo_cost,
    pp.avg_item_wholesale_cost,
    pp.stores_closed_on_start,
    ROW_NUMBER() OVER (ORDER BY pp.total_promo_cost DESC) AS rank
FROM page_promo_stats pp
ORDER BY pp.total_promo_cost DESC
LIMIT 100
