WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        c.c_region AS c_region,
        s.s_region AS s_region,
        c.c_mktsegment,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
)
SELECT
    c_region,
    s_region,
    c_mktsegment,
    p_category,
    d_year,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM filtered_orders
GROUP BY
    c_region,
    s_region,
    c_mktsegment,
    p_category,
    d_year
ORDER BY
    total_profit DESC
LIMIT 100
