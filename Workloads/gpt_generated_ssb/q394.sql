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
        lo.lo_quantity,
        lo.lo_tax,
        d.d_year,
        d.d_date,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        d_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        SUM(lo_quantity) AS total_quantity
    FROM filtered_orders
    GROUP BY d_year, c_region, p_category
),
ranked AS (
    SELECT
        d_year,
        c_region,
        p_category,
        total_revenue,
        avg_discount,
        distinct_orders,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year, c_region ORDER BY total_revenue DESC) AS rn
    FROM aggregated
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    avg_discount,
    distinct_orders,
    total_quantity
FROM ranked
WHERE rn <= 5
ORDER BY d_year, c_region, rn
