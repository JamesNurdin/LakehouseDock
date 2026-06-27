WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE d.d_year BETWEEN '1993' AND '1997'
),
commit_dates AS (
    SELECT
        od.lo_orderkey,
        od.lo_linenumber,
        od.lo_custkey,
        od.lo_partkey,
        od.lo_suppkey,
        od.lo_orderdate,
        od.lo_commitdate,
        od.lo_revenue,
        od.lo_supplycost,
        od.lo_quantity,
        od.lo_extendedprice,
        od.lo_ordertotalprice,
        od.lo_discount,
        od.lo_tax,
        od.lo_shipmode,
        od.order_year,
        cd.d_year AS commit_year
    FROM order_dates od
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS INTEGER) = od.lo_commitdate
    WHERE cd.d_year >= '1995'
),
aggregated AS (
    SELECT
        c.c_region AS c_region,
        s.s_region AS s_region,
        co.order_year AS order_year,
        p.p_category AS p_category,
        SUM(co.lo_revenue) AS total_revenue,
        SUM(co.lo_revenue - co.lo_supplycost) AS total_profit,
        COUNT(DISTINCT co.lo_orderkey) AS order_cnt
    FROM commit_dates co
    JOIN customer c
      ON co.lo_custkey = c.c_custkey
    JOIN supplier s
      ON co.lo_suppkey = s.s_suppkey
    JOIN part p
      ON co.lo_partkey = p.p_partkey
    GROUP BY c.c_region, s.s_region, co.order_year, p.p_category
)
SELECT
    c_region,
    s_region,
    order_year,
    p_category,
    total_revenue,
    total_profit,
    order_cnt,
    RANK() OVER (PARTITION BY c_region, s_region, order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 100
