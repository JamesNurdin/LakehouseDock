SELECT
    cp.cp_department,
    d_start.d_year,
    d_start.d_month_seq AS month_seq,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    SUM(cp.cp_catalog_page_number) AS total_page_numbers,
    AVG(cp.cp_catalog_number) AS avg_catalog_number,
    RANK() OVER (PARTITION BY d_start.d_year, d_start.d_month_seq ORDER BY SUM(cp.cp_catalog_page_number) DESC) AS dept_rank_in_month,
    CASE
        WHEN AVG(cp.cp_catalog_number) BETWEEN (SELECT MIN(ib_lower_bound) FROM income_band)
                                   AND (SELECT MAX(ib_upper_bound) FROM income_band)
        THEN 'Within Income Band'
        ELSE 'Outside Income Band'
    END AS income_band_flag,
    CASE
        WHEN MAX(CASE WHEN cp.cp_catalog_page_number > (SELECT AVG(t_hour) FROM time_dim) THEN 1 ELSE 0 END) = 1
        THEN 'Above Avg Hour'
        ELSE 'All Below Avg Hour'
    END AS hour_comparison_flag
FROM
    catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
WHERE
    cp.cp_type = 'monthly'
    AND d_start.d_year = 2023
    AND cp.cp_catalog_page_number >= 2
GROUP BY
    cp.cp_department,
    d_start.d_year,
    d_start.d_month_seq
HAVING
    COUNT(*) > 5
ORDER BY
    total_page_numbers DESC,
    cp.cp_department
