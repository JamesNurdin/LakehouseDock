WITH lineorder_supplier AS (
    SELECT
        lo.lo_suppkey,
        lo.lo_shipmode,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        lo.lo_orderkey,
        s.s_name,
        s.s_region,
        s.s_nation
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
),
profit_agg AS (
    SELECT
        s_region,
        s_nation,
        lo_shipmode,
        SUM(lo_quantity) AS total_quantity,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count
    FROM lineorder_supplier
    GROUP BY s_region, s_nation, lo_shipmode
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    total_quantity,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM profit_agg
ORDER BY total_profit DESC
LIMIT 20
