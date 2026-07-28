WITH inner_data AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'NonHoliday' END AS holiday_flag
    FROM inventory i
    INNER JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_quantity_on_hand > 0                               -- predicate 1
      AND d.d_year BETWEEN 1999 AND 2002                            -- predicate 2
      AND d.d_month_seq BETWEEN 1200 AND 1250                      -- predicate 3
      AND d.d_weekend = 'N'                                         -- predicate 4
      AND d.d_current_week = 'N'                                    -- predicate 5
),
left_data AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'NonHoliday' END AS holiday_flag
    FROM inventory i
    LEFT OUTER JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_warehouse_sk IN (4, 8, 10, 11, 14)                -- predicate 6
      AND i.inv_item_sk > 101400                                   -- predicate 7
      AND d.d_year IS NOT NULL                                     -- predicate 8
      AND d.d_weekend = 'N'                                         -- predicate 9
      AND d.d_current_week = 'N'                                    -- predicate 10
)
SELECT
    inv_warehouse_sk,
    inv_item_sk,
    d_year,
    total_qty,
    cnt,
    holiday_flag,
    rn
FROM (
    SELECT
        inv_warehouse_sk,
        inv_item_sk,
        d_year,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS cnt,
        holiday_flag,
        ROW_NUMBER() OVER (
            PARTITION BY inv_warehouse_sk
            ORDER BY SUM(inv_quantity_on_hand) DESC
        ) AS rn
    FROM (
        SELECT inv_warehouse_sk,
               inv_item_sk,
               inv_quantity_on_hand,
               d_year,
               holiday_flag
        FROM inner_data
        UNION ALL
        SELECT inv_warehouse_sk,
               inv_item_sk,
               inv_quantity_on_hand,
               d_year,
               holiday_flag
        FROM left_data
    ) u
    GROUP BY inv_warehouse_sk, inv_item_sk, d_year, holiday_flag
) ranked
WHERE rn <= 10
ORDER BY inv_warehouse_sk, rn
LIMIT 100
