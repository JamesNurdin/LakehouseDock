WITH order_agg AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_category,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_tax) AS total_tax,
        SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
    GROUP BY s.s_suppkey, s.s_name, p.p_category
)
SELECT
    s_name,
    p_category,
    total_extendedprice,
    total_revenue,
    total_supplycost,
    total_tax,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY total_profit DESC) AS profit_rank
FROM order_agg
ORDER BY total_profit DESC
LIMIT 10
