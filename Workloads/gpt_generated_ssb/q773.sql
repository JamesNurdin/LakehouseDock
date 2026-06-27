WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_orderpriority,
        lo.lo_shipmode,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year,
        date_diff('day', date(d_order.d_date), date(d_commit.d_date)) AS days_to_commit
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE date(d_order.d_date) BETWEEN DATE '1993-01-01' AND DATE '1995-12-31'
)
SELECT
    filtered_orders.d_year AS year,
    supplier.s_region AS supplier_region,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_supplycost) AS total_supply_cost,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    AVG(filtered_orders.lo_discount) AS avg_discount,
    AVG(filtered_orders.days_to_commit) AS avg_days_to_commit,
    COUNT(DISTINCT filtered_orders.lo_orderkey) AS order_cnt
FROM filtered_orders
JOIN part
    ON filtered_orders.lo_partkey = part.p_partkey
JOIN supplier
    ON filtered_orders.lo_suppkey = supplier.s_suppkey
WHERE part.p_category = 'MFGR#12'
  AND filtered_orders.lo_orderpriority = '1-URGENT'
  AND filtered_orders.lo_shipmode = 'AIR'
GROUP BY filtered_orders.d_year, supplier.s_region
ORDER BY filtered_orders.d_year, supplier.s_region
