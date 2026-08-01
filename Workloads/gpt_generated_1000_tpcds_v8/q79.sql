WITH combined_inventory AS (
    SELECT i.inv_item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           MAX(d.d_date) AS latest_date
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY i.inv_item_sk, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.inv_item_sk,
           d.d_year,
           d.d_month_seq,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           MAX(d.d_date) AS latest_date
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY i.inv_item_sk, d.d_year, d.d_month_seq
),
distinct_monthly AS (
    SELECT DISTINCT inv_item_sk,
                    d_year,
                    d_month_seq,
                    total_qty,
                    latest_date
    FROM combined_inventory
)
SELECT dm.inv_item_sk,
       dm.d_year,
       dm.d_month_seq,
       dm.total_qty,
       (
           SELECT SUM(i2.inv_quantity_on_hand)
           FROM inventory i2
           WHERE i2.inv_item_sk = dm.inv_item_sk
       ) AS overall_quantity,
       dm.latest_date
FROM distinct_monthly dm
ORDER BY dm.inv_item_sk,
         dm.d_year DESC,
         dm.d_month_seq
LIMIT 100
