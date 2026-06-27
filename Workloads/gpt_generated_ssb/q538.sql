WITH order_info AS (
    SELECT
        CAST(od.d_year AS INTEGER) AS order_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        DATE(od.d_date) AS order_date,
        DATE(cd.d_date) AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year BETWEEN '1992' AND '1997'
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    part_category,
    COUNT(*) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(DATE_DIFF('day', order_date, commit_date)) AS avg_lead_days
FROM order_info
GROUP BY order_year, customer_region, supplier_region, part_category
HAVING COUNT(*) > 5
ORDER BY total_revenue DESC
LIMIT 30
