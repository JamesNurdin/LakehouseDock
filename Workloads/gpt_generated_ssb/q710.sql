WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
enriched AS (
    SELECT
        fo.lo_orderkey,
        fo.lo_extendedprice,
        fo.lo_discount,
        fo.lo_revenue,
        fo.lo_tax,
        fo.lo_shipmode,
        fo.d_year,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM filtered_orders fo
    JOIN customer c
        ON fo.lo_custkey = c.c_custkey
    JOIN part p
        ON fo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON fo.lo_suppkey = s.s_suppkey
)
SELECT
    enriched.d_year,
    enriched.c_region,
    enriched.p_category,
    SUM(enriched.lo_revenue) AS total_revenue,
    SUM(enriched.lo_extendedprice * (1 - enriched.lo_discount / 100.0)) AS net_sales,
    AVG(enriched.lo_tax) AS avg_tax
FROM enriched
GROUP BY enriched.d_year, enriched.c_region, enriched.p_category
HAVING SUM(enriched.lo_revenue) > 1000000
ORDER BY enriched.d_year, enriched.c_region, enriched.p_category
