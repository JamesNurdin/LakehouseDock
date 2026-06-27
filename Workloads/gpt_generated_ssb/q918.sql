/* Revenue, profit and discount analysis by order year, supplier region, and part category */
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
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
)
SELECT
    od.order_year,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    SUM(od.lo_revenue - od.lo_supplycost) / SUM(od.lo_revenue) AS profit_margin,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE od.order_year BETWEEN '1995' AND '1997'
GROUP BY od.order_year, s.s_region, p.p_category
ORDER BY od.order_year, s.s_region, p.p_category
