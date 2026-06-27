WITH enriched_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_tax,
        lo_shipmode,
        lo_orderpriority,
        lo_shippriority,
        lo_commitdate,
        lo_linenumber
    FROM lineorder
)
SELECT
    dim_date.d_year,
    dim_date.d_month,
    supplier.s_region,
    part.p_category,
    sum(enriched_orders.lo_revenue) AS total_revenue,
    sum(enriched_orders.lo_revenue - enriched_orders.lo_supplycost) AS total_profit,
    avg(enriched_orders.lo_discount) AS avg_discount,
    count(distinct enriched_orders.lo_orderkey) AS order_count
FROM enriched_orders
JOIN dim_date
    ON cast(enriched_orders.lo_orderdate AS varchar) = dim_date.d_datekey
JOIN part
    ON enriched_orders.lo_partkey = part.p_partkey
JOIN supplier
    ON enriched_orders.lo_suppkey = supplier.s_suppkey
JOIN customer
    ON enriched_orders.lo_custkey = customer.c_custkey
WHERE cast(dim_date.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY dim_date.d_year, dim_date.d_month, supplier.s_region, part.p_category
ORDER BY total_profit DESC
LIMIT 20
