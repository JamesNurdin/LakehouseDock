WITH lo_cust_part AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_orderdate,
        lo.lo_shipmode,
        c.c_region,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        p.p_color
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_shipmode = 'AIR'
),
agg AS (
    SELECT
        c_region,
        c_mktsegment,
        p_category,
        p_brand1,
        p_color,
        SUM(lo_quantity) AS total_quantity,
        SUM(lo_extendedprice) AS total_extendedprice,
        SUM(lo_discount) AS total_discount,
        SUM(lo_revenue) AS total_revenue,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM lo_cust_part
    GROUP BY c_region, c_mktsegment, p_category, p_brand1, p_color
)
SELECT
    c_region,
    c_mktsegment,
    p_category,
    p_brand1,
    p_color,
    total_quantity,
    total_extendedprice,
    total_discount,
    total_revenue,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 200
