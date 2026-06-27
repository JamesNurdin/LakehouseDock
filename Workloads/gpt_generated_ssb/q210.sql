WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        c.c_region AS customer_region,
        c.c_nation AS customer_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE c.c_region = 'ASIA'
)
SELECT
    base.order_year,
    base.customer_region,
    base.p_category,
    SUM(base.profit) AS total_profit,
    SUM(base.lo_revenue) AS total_revenue,
    AVG(base.lo_discount) AS avg_discount,
    COUNT(DISTINCT base.lo_orderkey) AS distinct_orders
FROM base
GROUP BY
    base.order_year,
    base.customer_region,
    base.p_category
ORDER BY total_profit DESC
LIMIT 10
