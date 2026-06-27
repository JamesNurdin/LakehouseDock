WITH revenue_by_supplier AS (
    SELECT
        od.d_year AS order_year,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count,
        AVG(date_diff('day', date_parse(od.d_date, '%Y-%m-%d'), date_parse(cd.d_date, '%Y-%m-%d'))) AS avg_order_to_commit_days
    FROM lineorder lo
    JOIN dim_date od
        ON cast(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON cast(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
    GROUP BY od.d_year, s.s_region
)
SELECT
    order_year,
    supplier_region,
    total_revenue,
    total_quantity,
    avg_discount,
    order_count,
    avg_order_to_commit_days,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_supplier
ORDER BY order_year, revenue_rank
