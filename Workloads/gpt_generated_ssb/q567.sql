WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_shipmode,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_commitdate,
        d.d_year,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_shipmode = 'AIR'
      AND d.d_year BETWEEN '1995' AND '1997'
)
SELECT
    d_year,
    p_category,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT s_region) AS distinct_supplier_regions
FROM order_data
GROUP BY d_year, p_category
ORDER BY total_revenue DESC
LIMIT 10
