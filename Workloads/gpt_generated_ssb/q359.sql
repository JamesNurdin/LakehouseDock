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
        CAST(d_order.d_year AS integer) AS order_year,
        d_order.d_date AS order_date,
        CAST(d_commit.d_year AS integer) AS commit_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    s.s_region,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_quantity) AS total_quantity
FROM order_dates od
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE p.p_mfgr = 'MFGR#1'
    AND od.order_year = 1995
    AND od.commit_year >= od.order_year
GROUP BY s.s_region, od.order_year
ORDER BY total_revenue DESC
LIMIT 10
