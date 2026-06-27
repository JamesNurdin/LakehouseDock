WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        d.d_year AS order_year
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE p.p_category = 'MFGR#25'
      AND CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
region_revenue AS (
    SELECT
        fo.order_year,
        c.c_region,
        s.s_region AS supplier_region,
        SUM(fo.lo_revenue) AS total_revenue,
        AVG(fo.lo_discount) AS avg_discount,
        COUNT(DISTINCT fo.lo_orderkey) AS distinct_orders
    FROM filtered_orders fo
    JOIN customer c
        ON fo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON fo.lo_suppkey = s.s_suppkey
    GROUP BY fo.order_year, c.c_region, s.s_region
)
SELECT
    rr.order_year,
    rr.c_region,
    rr.supplier_region,
    rr.total_revenue,
    rr.avg_discount,
    rr.distinct_orders,
    rr.total_revenue * 100.0 / SUM(rr.total_revenue) OVER (PARTITION BY rr.order_year) AS revenue_pct_of_year
FROM region_revenue rr
ORDER BY rr.total_revenue DESC
LIMIT 20
