WITH closed_stores AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_geography_class,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_tax_percentage,
        d.d_year,
        d.d_weekend,
        d.d_following_holiday,
        d.d_date,
        CASE WHEN s.s_tax_percentage > 5.0 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND s.s_geography_class = 'Urban'
      AND s.s_number_employees BETWEEN 50 AND 500
      AND d.d_year = 2002
      AND d.d_weekend = 'N'
      AND d.d_following_holiday = 'N'
),
store_subset_a AS (
    SELECT s_store_sk FROM closed_stores WHERE s_floor_space > 2000
),
store_subset_b AS (
    SELECT s_store_sk FROM closed_stores WHERE s_number_employees < 200
),
intersected_stores AS (
    SELECT s_store_sk FROM store_subset_a
    INTERSECT
    SELECT s_store_sk FROM store_subset_b
),
agg AS (
    SELECT
        cs.s_state,
        cs.s_geography_class,
        cs.tax_category,
        COUNT(DISTINCT cs.s_store_sk) AS store_count,
        SUM(cs.s_floor_space) AS total_floor_space,
        AVG(cs.s_number_employees) AS avg_employees,
        MIN(cs.d_date) AS earliest_close_date,
        MAX(cs.d_date) AS latest_close_date
    FROM closed_stores cs
    WHERE cs.s_store_sk IN (SELECT s_store_sk FROM intersected_stores)
      AND EXISTS (
          SELECT 1
          FROM date_dim d2
          WHERE d2.d_date = cs.d_date
            AND d2.d_same_day_ly = 2414669
      )
    GROUP BY cs.s_state, cs.s_geography_class, cs.tax_category
)
SELECT
    s_state,
    s_geography_class,
    tax_category,
    store_count,
    total_floor_space,
    avg_employees,
    earliest_close_date,
    latest_close_date,
    ROW_NUMBER() OVER (ORDER BY total_floor_space DESC) AS rn
FROM agg
ORDER BY store_count DESC, total_floor_space DESC
LIMIT 100
