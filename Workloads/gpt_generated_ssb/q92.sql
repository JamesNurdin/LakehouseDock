WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    c.c_region,
    s.s_region AS supplier_region,
    p.p_category,
    od.order_year,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders,
    SUM(od.lo_quantity) AS total_quantity,
    SUM(od.lo_extendedprice) AS total_extended_price,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    SUM(od.lo_discount) AS total_discount,
    AVG(CAST(od.lo_discount AS double) / 100) AS avg_discount_rate,
    SUM(CASE WHEN od.commit_year = od.order_year THEN 1 ELSE 0 END) AS same_year_commit_cnt
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.order_year
ORDER BY total_revenue DESC
LIMIT 100
