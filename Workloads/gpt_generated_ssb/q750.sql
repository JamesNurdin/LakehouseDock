WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
)
SELECT
    c.c_region,
    od.order_year,
    p.p_category,
    s.s_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(*) AS order_line_count,
    RANK() OVER (PARTITION BY od.order_year ORDER BY SUM(od.lo_revenue) DESC) AS revenue_rank
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1997'
GROUP BY c.c_region, od.order_year, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 20
