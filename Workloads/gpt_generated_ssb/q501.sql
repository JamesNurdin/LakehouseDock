WITH revenue_by_region_category AS (
    SELECT
        d.d_year AS order_year,
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year BETWEEN '1992' AND '1997'
      AND c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_category = 'MFGR#12'
    GROUP BY d.d_year, s.s_region, p.p_category
),
ranked_combos AS (
    SELECT
        order_year,
        s_region,
        p_category,
        total_revenue,
        total_profit,
        order_count,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS rn
    FROM revenue_by_region_category
)
SELECT
    order_year,
    s_region,
    p_category,
    total_revenue,
    total_profit,
    order_count,
    avg_discount
FROM ranked_combos
WHERE rn <= 3
ORDER BY order_year, total_revenue DESC
