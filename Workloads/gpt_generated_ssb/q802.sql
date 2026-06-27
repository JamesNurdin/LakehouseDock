WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year        AS order_year,
        d_order.d_month       AS order_month,
        d_commit.d_year       AS commit_year,
        p.p_category          AS part_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE CAST(d_order.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region,
    s.s_region          AS supplier_region,
    od.order_year,
    od.order_month,
    od.part_category,
    SUM(od.lo_revenue)   AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_details od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    s.s_region,
    od.order_year,
    od.order_month,
    od.part_category
ORDER BY total_revenue DESC
LIMIT 100
