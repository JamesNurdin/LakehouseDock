WITH closed_stores AS (
    SELECT
        store.s_store_sk,
        store.s_store_id,
        store.s_store_name,
        store.s_state,
        store.s_city,
        store.s_number_employees,
        store.s_floor_space,
        store.s_tax_percentage,
        date_dim.d_date,
        date_dim.d_year,
        date_dim.d_quarter_name,
        date_dim.d_month_seq
    FROM store
    JOIN date_dim
        ON store.s_closed_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2024-12-31'
)
SELECT
    d_year,
    d_quarter_name,
    COUNT(s_store_sk) AS closed_store_count,
    AVG(s_floor_space) AS avg_floor_space,
    SUM(s_number_employees) AS total_employees,
    AVG(s_tax_percentage) AS avg_tax_percentage,
    AVG(s_floor_space / NULLIF(s_number_employees, 0)) AS avg_floor_space_per_employee
FROM closed_stores
GROUP BY d_year, d_quarter_name
ORDER BY d_year DESC, d_quarter_name
