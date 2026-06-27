WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        c.c_region AS region,
        p.p_category AS category,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1997' AND '1998'
      AND c.c_region = 'ASIA'
)
SELECT
    order_year,
    region,
    category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS net_sales
FROM order_details
GROUP BY order_year, region, category
ORDER BY total_revenue DESC
LIMIT 20
