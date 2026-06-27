WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        c.c_region AS customer_region,
        p.p_category AS product_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
      AND lo.lo_discount < 5
)
SELECT
    order_year,
    customer_region,
    product_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
GROUP BY order_year, customer_region, product_category
ORDER BY total_revenue DESC
LIMIT 20
