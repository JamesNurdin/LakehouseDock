WITH revenue_by_region AS (
    SELECT
        d_order.d_year AS order_year,
        c.c_region AS customer_region,
        p.p_category AS part_category,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND lo.lo_discount BETWEEN 5 AND 20
    GROUP BY d_order.d_year, c.c_region, p.p_category, s.s_region
),
ranked_revenue AS (
    SELECT
        order_year,
        customer_region,
        part_category,
        supplier_region,
        total_revenue,
        ROW_NUMBER() OVER (PARTITION BY order_year, part_category ORDER BY total_revenue DESC) AS revenue_rank
    FROM revenue_by_region
)
SELECT
    order_year,
    customer_region,
    part_category,
    supplier_region,
    total_revenue
FROM ranked_revenue
WHERE revenue_rank <= 3
ORDER BY order_year, part_category, total_revenue DESC
