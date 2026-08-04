WITH max_qty AS (
    SELECT MAX(inv_quantity_on_hand) AS max_q
    FROM inventory
),
city_qty AS (
    SELECT 
        w.w_city,
        w.w_state,
        iq.total_qty,
        CASE WHEN iq.total_qty > 2000 THEN 'HIGH' ELSE 'LOW' END AS qty_category
    FROM warehouse w
    LEFT JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_qty
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_quantity_on_hand > 750
    ) iq ON true
    WHERE w.w_city IS NOT NULL
),
-- Cities where total quantity exceeds the overall maximum quantity (scalar subquery)
cities_above_max AS (
    SELECT DISTINCT w_city
    FROM city_qty
    WHERE total_qty > (SELECT max_q FROM max_qty)
),
-- Cities that have at least one inventory row with quantity >= 800
cities_with_large_item AS (
    SELECT DISTINCT w.w_city
    FROM warehouse w
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand >= 800
),
-- Intersection of the two city sets
intersect_cities AS (
    SELECT w_city FROM cities_above_max
    INTERSECT
    SELECT w_city FROM cities_with_large_item
)
SELECT 
    cq.w_city,
    cq.w_state,
    cq.total_qty,
    cq.qty_category
FROM city_qty cq
WHERE cq.w_city IN (SELECT w_city FROM intersect_cities)
UNION ALL
SELECT 
    w.w_city,
    w.w_state,
    0 AS total_qty,
    'NO_DATA' AS qty_category
FROM warehouse w
WHERE w.w_city NOT IN (SELECT w_city FROM intersect_cities)
ORDER BY total_qty DESC
LIMIT 100
