WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
)
SELECT
    c_region,
    p_category,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS num_orders,
    AVG(lo_quantity) AS avg_quantity,
    AVG(date_diff('day', date(order_date), date(commit_date))) AS avg_days_to_commit
FROM lo_joined
GROUP BY c_region, p_category, order_year
ORDER BY total_revenue DESC
LIMIT 10
