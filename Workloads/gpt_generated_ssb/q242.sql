WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        c.c_region,
        p.p_category,
        s.s_nation AS supplier_nation,
        CAST(d_order.d_year AS integer) AS order_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    c_region,
    supplier_nation,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
WHERE order_year = 1997
GROUP BY order_year, c_region, supplier_nation, p_category
ORDER BY total_profit DESC
LIMIT 100
