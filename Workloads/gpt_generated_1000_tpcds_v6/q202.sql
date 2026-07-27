WITH first_group AS (
    SELECT
        d.d_fy_year AS d_fy_year,
        d.d_day_name AS d_day_name,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_item_sk IN (101425, 101422)
      AND d.d_fy_year = 1901
    GROUP BY d.d_fy_year, d.d_day_name
    HAVING SUM(i.inv_quantity_on_hand) > 600
),
second_group AS (
    SELECT
        d.d_fy_year AS d_fy_year,
        d.d_day_name AS d_day_name,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_item_sk IN (101437, 101443)
      AND d.d_fy_year = 1910
    GROUP BY d.d_fy_year, d.d_day_name
    HAVING SUM(i.inv_quantity_on_hand) > 600
)
SELECT
    u.d_fy_year,
    u.d_day_name,
    u.total_quantity
FROM (
    SELECT * FROM first_group
    UNION ALL
    SELECT * FROM second_group
) AS u
ORDER BY u.d_fy_year, u.d_day_name
