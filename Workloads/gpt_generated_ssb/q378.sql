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
        d.d_year,
        d.d_month,
        s.s_region,
        p.p_category,
        c.c_region
    FROM lineorder lo
    JOIN dim_date d
      ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_custkey) AS distinct_customers
FROM filtered_orders
GROUP BY d_year, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
