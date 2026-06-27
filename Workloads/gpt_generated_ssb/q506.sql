WITH brand_year_revenue AS (
    SELECT
        d.d_year,
        p.p_brand1,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS brand_revenue
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    GROUP BY d.d_year, p.p_brand1
)
SELECT
    byr.d_year,
    byr.p_brand1,
    byr.brand_revenue,
    SUM(byr.brand_revenue) OVER (PARTITION BY byr.d_year) AS total_year_revenue,
    byr.brand_revenue / SUM(byr.brand_revenue) OVER (PARTITION BY byr.d_year) AS revenue_share
FROM brand_year_revenue byr
ORDER BY byr.d_year DESC, revenue_share DESC
