WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        od.d_year,
        s.s_name,
        s.s_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    JOIN part p       ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#12'
      AND lo.lo_commitdate > lo.lo_orderdate
),
agg_by_supplier AS (
    SELECT
        fo.d_year,
        fo.s_region,
        fo.s_name,
        SUM(fo.lo_revenue) AS total_revenue,
        AVG(fo.lo_discount) AS avg_discount,
        COUNT(DISTINCT fo.lo_orderkey) AS order_count
    FROM filtered_orders fo
    GROUP BY fo.d_year, fo.s_region, fo.s_name
),
ranked_suppliers AS (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_revenue DESC) AS revenue_rank
    FROM agg_by_supplier a
)
SELECT
    r.d_year,
    r.s_region,
    r.s_name,
    r.total_revenue,
    r.avg_discount,
    r.order_count,
    r.revenue_rank
FROM ranked_suppliers r
WHERE r.revenue_rank <= 5
ORDER BY r.d_year, r.revenue_rank
