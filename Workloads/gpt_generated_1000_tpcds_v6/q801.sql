WITH agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM tpcds.inventory i
    LEFT JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.inv_quantity_on_hand > 0                     -- predicate 1
        AND i.inv_warehouse_sk IN (20, 8, 14)          -- predicate 2
        AND w.w_county = 'Mobile County'              -- predicate 3
        AND i.inv_date_sk BETWEEN 2450940 AND 2450950 -- predicate 4 (additional)
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        i.inv_item_sk
    HAVING
        SUM(i.inv_quantity_on_hand) > 300
)
SELECT
    a.w_warehouse_id,
    a.w_city,
    a.inv_item_sk,
    a.total_qty,
    CASE
        WHEN a.total_qty >= 1000 THEN 'High'
        WHEN a.total_qty >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category,
    RANK() OVER (PARTITION BY a.w_city ORDER BY a.total_qty DESC) AS city_qty_rank,
    ROW_NUMBER() OVER (ORDER BY a.total_qty DESC) AS overall_rank
FROM agg a
ORDER BY a.total_qty DESC
LIMIT 100
