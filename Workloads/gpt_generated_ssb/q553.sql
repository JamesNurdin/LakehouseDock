WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year,
        d_order.d_month,
        c.c_nation,
        c.c_region,
        p.p_category,
        p.p_brand1,
        s.s_nation,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
)
SELECT
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_supplycost) AS total_supplycost,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM filtered_orders
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
