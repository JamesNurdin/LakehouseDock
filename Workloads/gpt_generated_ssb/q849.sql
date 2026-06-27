WITH order_details AS (
    SELECT
        lo.lo_orderkey,
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
        od.d_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_nation
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
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)

SELECT
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM order_details
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
