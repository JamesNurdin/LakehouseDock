WITH agg AS (
    SELECT
        order_dim.d_year,
        cust.c_region,
        part.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date order_dim
        ON CAST(lo.lo_orderdate AS varchar) = order_dim.d_datekey
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    WHERE order_dim.d_year = '1995'
    GROUP BY order_dim.d_year, cust.c_region, part.p_category
)
SELECT
    agg.d_year,
    agg.c_region,
    agg.p_category,
    agg.total_revenue,
    agg.total_profit,
    agg.avg_discount,
    agg.order_cnt,
    agg.total_revenue / SUM(agg.total_revenue) OVER (PARTITION BY agg.d_year) AS revenue_share,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.d_year, revenue_rank
LIMIT 100
