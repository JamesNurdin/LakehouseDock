WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        s.s_region AS supplier_region,
        c.c_mktsegment AS customer_segment
    FROM lineorder lo
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    order_year,
    supplier_region,
    COUNT(*) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_days
FROM order_details
GROUP BY order_year, supplier_region
ORDER BY total_revenue DESC
