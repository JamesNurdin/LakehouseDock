WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year AS od_year,
        lo.lo_orderdate,
        lo.lo_commitdate
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    WHERE od.d_year = '1995'
      AND cd.d_holidayfl = 'Y'
)
SELECT
    fo.od_year,
    c.c_region,
    s.s_nation,
    p.p_category,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_orderkey) AS order_count
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY fo.od_year, c.c_region, s.s_nation, p.p_category
ORDER BY total_revenue DESC
LIMIT 50
