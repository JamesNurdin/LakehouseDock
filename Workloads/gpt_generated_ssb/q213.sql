WITH part_rev AS (
    SELECT
        p.p_category,
        p.p_brand1,
        p.p_partkey,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_quantity) AS total_quantity,
        AVG(l.lo_discount) AS avg_discount
    FROM lineorder l
    JOIN part p
        ON l.lo_partkey = p.p_partkey
    GROUP BY p.p_category, p.p_brand1, p.p_partkey
),
ranked AS (
    SELECT
        p_category,
        p_brand1,
        p_partkey,
        total_revenue,
        total_quantity,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS rn
    FROM part_rev
)
SELECT
    p_category,
    p_brand1,
    p_partkey,
    total_revenue,
    total_quantity,
    avg_discount,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY p_category, rn
