WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    d_year,
    s_region,
    sum(lo_revenue) AS total_revenue,
    sum(lo_revenue - lo_supplycost) AS total_profit,
    avg(lo_discount) AS avg_discount,
    count(distinct lo_orderkey) AS num_orders,
    count(distinct lo_custkey) AS num_customers
FROM filtered_orders
GROUP BY d_year, s_region
ORDER BY total_revenue DESC
