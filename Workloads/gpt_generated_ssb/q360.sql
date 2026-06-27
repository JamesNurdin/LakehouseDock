WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        dim.d_year,
        cust.c_region AS cust_region,
        supp.s_region AS supp_region
    FROM lineorder lo
    JOIN dim_date dim
        ON lo.lo_orderdate = CAST(dim.d_datekey AS INTEGER)
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#12'
      AND CAST(dim.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    cust_region,
    supp_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM filtered_orders
GROUP BY d_year, cust_region, supp_region
ORDER BY total_revenue DESC
LIMIT 20
