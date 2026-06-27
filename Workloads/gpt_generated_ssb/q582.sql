WITH regional_sales AS (
    SELECT
        s.s_region,
        s.s_nation,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost * lo.lo_quantity) AS profit,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 30
      AND lo.lo_discount < 5
    GROUP BY s.s_region, s.s_nation, lo.lo_shipmode, lo.lo_orderpriority
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    lo_orderpriority,
    revenue,
    profit,
    order_cnt,
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM regional_sales
ORDER BY revenue DESC
LIMIT 50
