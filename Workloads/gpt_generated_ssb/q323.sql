WITH filtered_lineorder AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_orderpriority,
        lo_shippriority,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_commitdate,
        lo_shipmode
    FROM lineorder
    WHERE lo_quantity > 0
),
filtered_part AS (
    SELECT
        p_partkey,
        p_category,
        p_brand1,
        p_size
    FROM part
    WHERE p_size > 10
),
filtered_customer AS (
    SELECT
        c_custkey,
        c_region
    FROM customer
),
filtered_supplier AS (
    SELECT
        s_suppkey,
        s_region
    FROM supplier
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    SUM((lo.lo_revenue - lo.lo_supplycost) * 1.0) / SUM(lo.lo_revenue) AS profit_margin,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM filtered_lineorder lo
JOIN filtered_customer c ON lo.lo_custkey = c.c_custkey
JOIN filtered_part p ON lo.lo_partkey = p.p_partkey
JOIN filtered_supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY c.c_region, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10
