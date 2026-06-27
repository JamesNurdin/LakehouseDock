WITH order_dates AS (
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
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
      ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
      ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
), aggregated AS (
    SELECT
        od.order_year,
        c.c_region,
        p.p_category,
        s.s_region,
        s.s_suppkey,
        SUM(od.lo_revenue) AS total_revenue,
        AVG(od.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM order_dates od
    JOIN customer c
      ON od.lo_custkey = c.c_custkey
    JOIN part p
      ON od.lo_partkey = p.p_partkey
    JOIN supplier s
      ON od.lo_suppkey = s.s_suppkey
    WHERE od.order_year = '1995'
      AND p.p_category = 'MFGR#1'
    GROUP BY od.order_year, c.c_region, p.p_category, s.s_region, s.s_suppkey
)
SELECT
    order_year,
    c_region,
    p_category,
    s_region,
    s_suppkey,
    total_revenue,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY revenue_rank
LIMIT 10
