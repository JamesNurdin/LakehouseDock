WITH supplier_lineorder AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        sup.s_region,
        sup.s_nation,
        sup.s_name
    FROM lineorder lo
    JOIN supplier sup
        ON lo.lo_suppkey = sup.s_suppkey
)
SELECT
    s_region,
    s_nation,
    s_name,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    order_cnt,
    revenue_rank
FROM (
    SELECT
        s_region,
        s_nation,
        s_name,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_cnt,
        RANK() OVER (PARTITION BY s_region ORDER BY SUM(lo_revenue) DESC) AS revenue_rank
    FROM supplier_lineorder
    GROUP BY s_region, s_nation, s_name
) AS ranked
WHERE revenue_rank <= 3
ORDER BY s_region, revenue_rank
