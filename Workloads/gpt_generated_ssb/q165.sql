WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        d.d_year,
        d.d_month,
        d.d_dayofweek
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1995'
),
customer_regions AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_nation,
        c.c_mktsegment
    FROM customer c
    WHERE c.c_mktsegment = 'AUTOMOBILE'
),
part_categories AS (
    SELECT
        p.p_partkey,
        p.p_category,
        p.p_brand1,
        p.p_type
    FROM part p
    WHERE p.p_category = 'MFGR#1'
),
supplier_regions AS (
    SELECT
        s.s_suppkey,
        s.s_region,
        s.s_nation
    FROM supplier s
    WHERE s.s_region = 'EUROPE'
)
SELECT
    cr.c_region AS customer_region,
    sr.s_region AS supplier_region,
    od.d_year,
    od.d_month,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(od.lo_discount) AS avg_discount
FROM order_dates od
JOIN customer_regions cr
    ON od.lo_custkey = cr.c_custkey
JOIN part_categories pc
    ON od.lo_partkey = pc.p_partkey
JOIN supplier_regions sr
    ON od.lo_suppkey = sr.s_suppkey
GROUP BY cr.c_region, sr.s_region, od.d_year, od.d_month
ORDER BY total_revenue DESC
LIMIT 100
