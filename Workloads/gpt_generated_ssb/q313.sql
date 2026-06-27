WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_ordertotalprice,
        d.d_year,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1994'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    supplier_region,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM filtered_orders
GROUP BY supplier_region, p_category, p_brand1
ORDER BY total_revenue DESC
LIMIT 10
