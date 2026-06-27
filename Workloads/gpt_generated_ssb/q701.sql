WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        p.p_category,
        p.p_brand1,
        p.p_type,
        s.s_region,
        s.s_nation,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    s_region,
    p_category,
    order_year,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_days
FROM order_details
WHERE lo_shipmode = 'AIR'
  AND order_year = '1995'
GROUP BY s_region, p_category, order_year
HAVING SUM(lo_revenue) > 500000
ORDER BY total_revenue DESC
LIMIT 50
