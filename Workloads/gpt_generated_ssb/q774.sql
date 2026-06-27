WITH order_data AS (
    SELECT
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_extendedprice,
        lo.lo_quantity,
        d_order.d_year,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
      AND d_order.d_year BETWEEN '1995' AND '1997'
)
SELECT
    d_year,
    c_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_discount) AS total_discount,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_line_count,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(lo_revenue) DESC) AS region_rank,
    SUM(SUM(lo_revenue)) OVER (
        PARTITION BY c_region
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_by_region
FROM order_data
GROUP BY d_year, c_region
ORDER BY d_year, total_revenue DESC
