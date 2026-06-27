WITH lo_joined AS (
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
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year,
        od.d_month,
        od.d_date,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        p.p_category,
        p.p_brand1,
        s.s_region,
        c.c_region AS cust_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
)
SELECT
    d_year,
    d_month,
    p_category,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(DISTINCT lo_custkey) AS distinct_customers,
    AVG(lo_discount) AS avg_discount
FROM lo_joined
GROUP BY d_year, d_month, p_category, s_region
ORDER BY total_profit DESC
LIMIT 20
