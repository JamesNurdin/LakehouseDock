WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    od.order_year,
    s.s_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS profit,
    AVG(od.lo_discount) AS avg_discount
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
  AND od.commit_year = od.order_year
GROUP BY od.order_year, s.s_region
HAVING SUM(od.lo_revenue) > 1000000
ORDER BY profit DESC
LIMIT 10
