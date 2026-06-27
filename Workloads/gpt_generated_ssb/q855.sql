WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        d.d_year,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#1'
)
SELECT
    fo.d_year,
    cust.c_region,
    supp.s_region,
    fo.p_category,
    sum(fo.lo_revenue) AS total_revenue,
    sum(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    avg(fo.lo_discount) AS avg_discount,
    count(*) AS order_cnt
FROM filtered_orders fo
JOIN customer cust
    ON fo.lo_custkey = cust.c_custkey
JOIN supplier supp
    ON fo.lo_suppkey = supp.s_suppkey
GROUP BY fo.d_year, cust.c_region, supp.s_region, fo.p_category
ORDER BY total_revenue DESC
LIMIT 10
