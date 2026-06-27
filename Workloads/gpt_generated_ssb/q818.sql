WITH filtered_date AS (
    SELECT
        d_datekey,
        d_year,
        d_date
    FROM dim_date
    WHERE CAST(d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
order_revenue AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        (lo_extendedprice * (1 - lo_discount / 100.0)) AS revenue,
        (lo_extendedprice * lo_discount / 100.0) AS discount_amount
    FROM lineorder
)
SELECT
    fd.d_year,
    c.c_region,
    p.p_category,
    SUM(orr.revenue) AS total_revenue,
    SUM(orr.discount_amount) AS total_discount,
    COUNT(DISTINCT orr.lo_orderkey) AS order_count,
    AVG(orr.lo_quantity) AS avg_quantity
FROM order_revenue orr
JOIN filtered_date fd
    ON orr.lo_orderdate = CAST(fd.d_datekey AS INTEGER)
JOIN customer c
    ON orr.lo_custkey = c.c_custkey
JOIN part p
    ON orr.lo_partkey = p.p_partkey
GROUP BY fd.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100
