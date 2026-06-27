WITH order_metrics AS (
    SELECT
        c.c_region,
        d_order.d_year,
        p.p_category,
        s.s_nation,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_orderkey,
        date_diff('day', date(d_order.d_date), date(d_commit.d_date)) AS days_to_commit
    FROM lineorder lo
    JOIN dim_date d_order ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1995' AND '1996'
      AND c.c_region = 'ASIA'
)
SELECT
    c_region,
    d_year,
    p_category,
    s_nation,
    SUM(lo_extendedprice * (1 - lo_discount * 0.01)) AS total_revenue,
    SUM(lo_extendedprice * (1 - lo_discount * 0.01) - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(days_to_commit) AS avg_days_to_commit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_metrics
GROUP BY c_region, d_year, p_category, s_nation
ORDER BY total_revenue DESC
LIMIT 100
