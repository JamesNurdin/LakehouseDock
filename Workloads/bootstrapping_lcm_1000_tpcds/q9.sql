SELECT 
    agg.d_year,
    agg.d_current_month,
    agg.stores_closed,
    agg.total_floor_space,
    agg.avg_employees,
    agg.holiday_floor_space,
    agg.weekend_floor_space,
    agg.max_holiday_tax,
    agg.min_holiday_tax,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_floor_space DESC) AS rank_by_floor_space
FROM (
    SELECT 
        d.d_year,
        d.d_current_month,
        COUNT(DISTINCT s.s_store_id) AS stores_closed,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_number_employees) AS avg_employees,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN s.s_floor_space ELSE 0 END) AS holiday_floor_space,
        SUM(CASE WHEN d.d_weekend = 'Y' THEN s.s_floor_space ELSE 0 END) AS weekend_floor_space,
        MAX(CASE WHEN d.d_holiday = 'Y' THEN s.s_tax_percentage ELSE NULL END) AS max_holiday_tax,
        MIN(CASE WHEN d.d_holiday = 'Y' THEN s.s_tax_percentage ELSE NULL END) AS min_holiday_tax
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY d.d_year, d.d_current_month
) agg
WHERE agg.total_floor_space > 0
ORDER BY agg.d_year, rank_by_floor_space
LIMIT 100
