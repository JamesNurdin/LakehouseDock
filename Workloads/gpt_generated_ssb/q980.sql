WITH order_dates AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_quantity,
        lo_tax
    FROM lineorder
),
order_dim AS (
    SELECT
        od.lo_orderkey,
        od.lo_custkey,
        od.lo_suppkey,
        od.lo_revenue,
        od.lo_supplycost,
        od.lo_discount,
        od.lo_quantity,
        od.lo_tax,
        d_order.d_year AS order_year
    FROM order_dates od
    JOIN dim_date d_order
        ON od.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON od.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
)
SELECT
    c.c_region,
    s.s_nation,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dim od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year BETWEEN '1995' AND '1997'
GROUP BY c.c_region, s.s_nation, od.order_year
ORDER BY total_revenue DESC
LIMIT 20
