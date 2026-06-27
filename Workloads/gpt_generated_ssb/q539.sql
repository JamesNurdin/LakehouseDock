WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        d_ord.d_year AS order_year,
        d_com.d_year AS commit_year,
        s.s_region AS supplier_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d_ord
        ON lo.lo_orderdate = CAST(d_ord.d_datekey AS INTEGER)
    JOIN dim_date d_com
        ON lo.lo_commitdate = CAST(d_com.d_datekey AS INTEGER)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_ord.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
      AND CAST(d_com.d_year AS INTEGER) >= CAST(d_ord.d_year AS INTEGER)
)
SELECT
    supplier_region,
    p_category,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_enriched
GROUP BY supplier_region, p_category, order_year
ORDER BY total_revenue DESC
LIMIT 20
