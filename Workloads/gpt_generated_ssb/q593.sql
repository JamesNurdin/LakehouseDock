WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        sup.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    JOIN supplier sup
        ON lo.lo_suppkey = sup.s_suppkey
    WHERE od.d_year BETWEEN '1995' AND '1997'
)
SELECT
    order_year,
    supplier_region,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS profit,
    SUM(lo_revenue - lo_supplycost) / NULLIF(SUM(lo_revenue), 0) AS profit_margin,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_time_days,
    AVG(lo_discount) AS avg_discount
FROM lo_dates
GROUP BY order_year, supplier_region
ORDER BY order_year, supplier_region
