WITH cp_agg AS (
    SELECT
        td.t_shift,
        COUNT(cp.cp_catalog_page_sk) AS monthly_catalog_pages
    FROM
        catalog_page cp
        JOIN time_dim td ON cp.cp_start_date_sk = td.t_time_sk
    WHERE
        cp.cp_type = 'monthly'
    GROUP BY
        td.t_shift
)
SELECT
    s.s_state AS state,
    t.t_shift AS closed_shift,
    COUNT(DISTINCT s.s_store_sk) AS store_cnt,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(s.s_tax_percentage) AS avg_tax_pct,
    AVG(ca.ca_gmt_offset) AS avg_customer_gmt_offset,
    COALESCE(cp_agg.monthly_catalog_pages, 0) AS monthly_catalog_pages
FROM
    store s
    JOIN customer_address ca
        ON s.s_state = ca.ca_state AND s.s_zip = ca.ca_zip
    JOIN time_dim t
        ON s.s_closed_date_sk = t.t_time_sk
    LEFT JOIN cp_agg
        ON t.t_shift = cp_agg.t_shift
WHERE
    s.s_closed_date_sk IS NOT NULL
    AND ca.ca_gmt_offset IS NOT NULL
GROUP BY
    s.s_state,
    t.t_shift,
    cp_agg.monthly_catalog_pages
HAVING
    COUNT(DISTINCT s.s_store_sk) > 5
ORDER BY
    total_floor_space DESC
LIMIT 20
