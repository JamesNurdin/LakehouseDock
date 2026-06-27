WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year,
        c.c_region,
        s.s_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1997'
),
aggregated AS (
    SELECT
        d_year,
        c_region,
        s_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM order_details
    GROUP BY d_year, c_region, s_region, p_category
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    total_revenue,
    avg_discount,
    order_cnt,
    total_revenue * 100.0 / SUM(total_revenue) OVER (PARTITION BY d_year) AS revenue_pct_of_year
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 20
