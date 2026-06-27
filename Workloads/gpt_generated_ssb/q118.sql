WITH revenue_by_supplier_customer AS (
    SELECT
        s.s_suppkey,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        od_order.d_year AS order_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN dim_date od_order
        ON CAST(lo.lo_orderdate AS varchar) = od_order.d_datekey
    JOIN dim_date od_commit
        ON CAST(lo.lo_commitdate AS varchar) = od_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od_order.d_year = '1994'
      AND p.p_category = 'MFGR#12'
      AND c.c_region = 'ASIA'
    GROUP BY s.s_suppkey, s.s_region, c.c_region, od_order.d_year, p.p_category
)
SELECT
    supplier_region,
    customer_region,
    order_year,
    p_category,
    total_revenue,
    avg_discount,
    order_cnt,
    total_quantity,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_supplier_customer
ORDER BY order_year, revenue_rank
LIMIT 20
