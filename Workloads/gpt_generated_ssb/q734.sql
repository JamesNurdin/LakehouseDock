WITH yearly_region_sales AS (
    SELECT
        order_date.d_year AS order_year,
        supplier.s_region AS supplier_region,
        SUM(lineorder.lo_revenue) AS revenue,
        SUM(lineorder.lo_supplycost) AS supply_cost,
        SUM(lineorder.lo_revenue) - SUM(lineorder.lo_supplycost) AS profit,
        COUNT(DISTINCT lineorder.lo_orderkey) AS order_count,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN dim_date order_date
        ON lineorder.lo_orderdate = CAST(order_date.d_datekey AS integer)
    WHERE lineorder.lo_shipmode = 'AIR'
      AND order_date.d_year >= '1992'
      AND order_date.d_year <= '1995'
    GROUP BY order_date.d_year, supplier.s_region
)
SELECT
    order_year,
    supplier_region,
    revenue,
    supply_cost,
    profit,
    order_count,
    avg_discount,
    SUM(revenue) OVER (
        PARTITION BY supplier_region
        ORDER BY order_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM yearly_region_sales
ORDER BY supplier_region, order_year
