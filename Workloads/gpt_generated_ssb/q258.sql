WITH order_enriched AS (
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
        lo.lo_commitdate,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c_region,
    d_year,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_enriched
GROUP BY
    c_region,
    d_year,
    p_category
ORDER BY
    total_profit DESC
LIMIT 20
