WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    sum(od.lo_revenue) AS total_revenue,
    sum(od.lo_revenue - od.lo_supplycost) AS total_profit,
    avg(od.lo_discount) AS avg_discount,
    sum(od.lo_quantity) AS total_quantity,
    count(distinct od.lo_orderkey) AS distinct_orders,
    avg(date_diff('day', cast(od.order_date AS date), cast(od.commit_date AS date))) AS avg_days_to_commit
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1997'
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY od.order_year, c.c_region, p.p_category
