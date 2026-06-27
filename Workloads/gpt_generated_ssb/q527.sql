WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    od.d_yearmonth AS order_year_month,
    cd.d_month      AS commit_month,
    base.c_region,
    base.p_category,
    SUM(base.lo_extendedprice)                     AS total_extended_price,
    SUM(base.lo_revenue)                           AS total_revenue,
    SUM(base.lo_supplycost)                        AS total_supply_cost,
    SUM(base.lo_revenue - base.lo_supplycost)      AS total_profit,
    AVG(base.lo_discount)                          AS avg_discount,
    COUNT(DISTINCT base.lo_orderkey)               AS order_count
FROM base
JOIN dim_date od ON CAST(base.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd ON CAST(base.lo_commitdate AS varchar) = cd.d_datekey
WHERE od.d_year = '1995'
GROUP BY od.d_yearmonth, cd.d_month, base.c_region, base.p_category
HAVING SUM(base.lo_revenue - base.lo_supplycost) > 1000000
ORDER BY od.d_yearmonth, cd.d_month, base.c_region, base.p_category
