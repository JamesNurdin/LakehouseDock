WITH yearly_region_revenue AS (
    SELECT
        order_dim.d_year,
        supplier.s_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN dim_date order_dim
        ON CAST(order_dim.d_datekey AS INTEGER) = lineorder.lo_orderdate
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE part.p_category = 'MFGR#12'
      AND customer.c_mktsegment = 'AUTOMOBILE'
      AND order_dim.d_year = '1997'
    GROUP BY order_dim.d_year, supplier.s_region
)
SELECT
    d_year,
    s_region,
    total_revenue,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM yearly_region_revenue
ORDER BY d_year, revenue_rank
