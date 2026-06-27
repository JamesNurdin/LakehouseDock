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
        d_o.d_year AS order_year,
        d_c.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_o ON CAST(d_o.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_c ON CAST(d_c.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    SUM(od.lo_revenue - od.lo_supplycost) / NULLIF(SUM(od.lo_revenue), 0) AS profit_margin,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
  AND od.lo_discount > 0
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
