WITH category_revenue AS (
    SELECT
        lineorder.lo_shipmode,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_quantity) AS total_quantity,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_quantity > 10
    GROUP BY lineorder.lo_shipmode, part.p_category
)
SELECT
    lo_shipmode,
    p_category,
    total_revenue,
    total_quantity,
    avg_discount
FROM (
    SELECT
        lo_shipmode,
        p_category,
        total_revenue,
        total_quantity,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY lo_shipmode ORDER BY total_revenue DESC) AS rn
    FROM category_revenue
) t
WHERE rn <= 5
ORDER BY lo_shipmode, total_revenue DESC
