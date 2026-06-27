WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        c.c_region,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
      AND od.d_year = '1997'
      AND cd.d_year = '1997'
      AND lo.lo_discount < 5
)
SELECT
    order_year,
    c_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM filtered_orders
GROUP BY order_year, c_region
ORDER BY total_revenue DESC
