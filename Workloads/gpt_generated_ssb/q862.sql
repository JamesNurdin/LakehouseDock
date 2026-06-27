WITH agg AS (
    SELECT
        supplier.s_region,
        supplier.s_nation,
        lineorder.lo_shipmode,
        sum(lineorder.lo_revenue) AS total_revenue,
        sum(lineorder.lo_quantity) AS total_quantity,
        avg(lineorder.lo_discount) AS average_discount,
        count(distinct lineorder.lo_orderkey) AS distinct_orders,
        count(distinct lineorder.lo_custkey) AS distinct_customers
    FROM lineorder
    JOIN supplier
      ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE supplier.s_region = 'ASIA'
    GROUP BY supplier.s_region, supplier.s_nation, lineorder.lo_shipmode
)
SELECT
    agg.s_region,
    agg.s_nation,
    agg.lo_shipmode,
    agg.total_revenue,
    agg.total_quantity,
    agg.average_discount,
    agg.distinct_orders,
    agg.distinct_customers,
    rank() OVER (PARTITION BY agg.s_region ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.total_revenue DESC
LIMIT 20
