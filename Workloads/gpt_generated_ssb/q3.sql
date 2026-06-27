WITH lo_supp AS (
    SELECT
        lo.lo_shipmode,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderkey,
        s.s_region,
        s.s_nation
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderpriority = '1-URGENT'
),
agg AS (
    SELECT
        s_region,
        s_nation,
        lo_shipmode,
        sum(lo_revenue) AS total_revenue,
        sum(lo_supplycost) AS total_supply_cost,
        sum(lo_revenue - lo_supplycost) AS total_profit,
        avg(lo_discount) AS avg_discount,
        count(DISTINCT lo_orderkey) AS distinct_orders
    FROM lo_supp
    GROUP BY s_region, s_nation, lo_shipmode
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    distinct_orders,
    rank() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 20
