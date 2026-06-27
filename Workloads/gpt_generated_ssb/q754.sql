WITH revenue_by_supplier AS (
    SELECT
        supplier.s_region,
        supplier.s_nation,
        sum(lineorder.lo_revenue) AS total_revenue,
        sum(lineorder.lo_extendedprice) AS total_extendedprice,
        sum(lineorder.lo_supplycost * lineorder.lo_quantity) AS total_supplycost,
        sum(lineorder.lo_revenue) - sum(lineorder.lo_supplycost * lineorder.lo_quantity) AS total_profit,
        count(distinct lineorder.lo_orderkey) AS order_count
    FROM lineorder
    JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE lineorder.lo_orderpriority IN ('1-URGENT', '2-HIGH')
    GROUP BY supplier.s_region, supplier.s_nation
)
SELECT
    s_region,
    s_nation,
    total_revenue,
    total_profit,
    order_count,
    rank() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_supplier
ORDER BY total_revenue DESC
LIMIT 10
