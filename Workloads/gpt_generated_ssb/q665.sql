WITH agg AS (
    SELECT
        od.d_year AS d_year,
        p.p_category AS p_category,
        c.c_mktsegment AS c_mktsegment,
        s.s_region AS s_region,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_supplycost) AS total_supplycost,
        (sum(lo.lo_revenue) - sum(lo.lo_supplycost)) AS total_profit,
        avg(lo.lo_discount) AS avg_discount,
        avg(lo.lo_shippriority) AS avg_shippriority
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year BETWEEN '1992' AND '1997'
    GROUP BY od.d_year, p.p_category, c.c_mktsegment, s.s_region
)
SELECT
    d_year,
    p_category,
    c_mktsegment,
    s_region,
    total_revenue,
    total_supplycost,
    total_profit,
    (total_profit * 1.0) / nullif(total_revenue, 0) AS profit_margin,
    avg_discount,
    avg_shippriority
FROM (
    SELECT
        d_year,
        p_category,
        c_mktsegment,
        s_region,
        total_revenue,
        total_supplycost,
        total_profit,
        avg_discount,
        avg_shippriority,
        row_number() OVER (
            PARTITION BY d_year
            ORDER BY (total_profit * 1.0) / nullif(total_revenue, 0) DESC
        ) AS rn
    FROM agg
) ranked
WHERE rn <= 5
ORDER BY d_year, rn
