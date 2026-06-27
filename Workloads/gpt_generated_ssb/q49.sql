WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_commitdate,
        d.d_date,
        d.d_year,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_extendedprice) AS avg_extendedprice,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count
FROM orders
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
