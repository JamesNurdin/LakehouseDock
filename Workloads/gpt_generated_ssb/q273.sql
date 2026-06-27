WITH filtered_lineorder_supplier AS (
    SELECT
        lineorder.lo_suppkey,
        lineorder.lo_shipmode,
        lineorder.lo_quantity,
        lineorder.lo_discount,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        supplier.s_region,
        supplier.s_nation
    FROM lineorder
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE lineorder.lo_quantity > 30
      AND supplier.s_region = 'ASIA'
)
SELECT
    t.s_region,
    t.s_nation,
    t.lo_shipmode,
    t.total_revenue,
    t.total_supplycost,
    t.total_profit,
    t.avg_discount,
    t.order_count,
    row_number() OVER (PARTITION BY t.s_region ORDER BY t.total_revenue DESC) AS region_rank
FROM (
    SELECT
        filtered_lineorder_supplier.s_region,
        filtered_lineorder_supplier.s_nation,
        filtered_lineorder_supplier.lo_shipmode,
        sum(filtered_lineorder_supplier.lo_revenue) AS total_revenue,
        sum(filtered_lineorder_supplier.lo_supplycost) AS total_supplycost,
        sum(filtered_lineorder_supplier.lo_revenue - filtered_lineorder_supplier.lo_supplycost) AS total_profit,
        avg(filtered_lineorder_supplier.lo_discount) AS avg_discount,
        count(*) AS order_count
    FROM filtered_lineorder_supplier
    GROUP BY filtered_lineorder_supplier.s_region,
             filtered_lineorder_supplier.s_nation,
             filtered_lineorder_supplier.lo_shipmode
) t
ORDER BY t.total_revenue DESC
LIMIT 50
