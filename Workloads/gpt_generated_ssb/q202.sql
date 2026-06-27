WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        d.d_year,
        c.c_region,
        s.s_region,
        p.p_category,
        p.p_brand1,
        SUM(f.lo_revenue) AS total_revenue,
        SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
        COUNT(DISTINCT f.lo_orderkey) AS distinct_orders,
        AVG(f.lo_quantity) AS avg_quantity
    FROM filtered_orders f
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = f.lo_orderdate
    JOIN customer c
        ON f.lo_custkey = c.c_custkey
    JOIN supplier s
        ON f.lo_suppkey = s.s_suppkey
    JOIN part p
        ON f.lo_partkey = p.p_partkey
    GROUP BY
        d.d_year,
        c.c_region,
        s.s_region,
        p.p_category,
        p.p_brand1
)
SELECT
    d_year AS order_year,
    c_region AS customer_region,
    s_region AS supplier_region,
    p_category AS part_category,
    p_brand1 AS part_brand,
    total_revenue,
    total_profit,
    distinct_orders,
    avg_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY
    d_year,
    total_revenue DESC
