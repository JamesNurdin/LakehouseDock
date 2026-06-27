WITH order_date AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year BETWEEN '1995' AND '1997'
),
customer_dim AS (
    SELECT
        c.c_custkey,
        c.c_region
    FROM customer c
),
part_dim AS (
    SELECT
        p.p_partkey,
        p.p_category
    FROM part p
),
supplier_dim AS (
    SELECT
        s.s_suppkey,
        s.s_region
    FROM supplier s
)
SELECT
    od.d_year,
    cust.c_region,
    part_dim.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_date od
JOIN customer_dim cust ON od.lo_custkey = cust.c_custkey
JOIN part_dim ON od.lo_partkey = part_dim.p_partkey
JOIN supplier_dim ON od.lo_suppkey = supplier_dim.s_suppkey
GROUP BY od.d_year, cust.c_region, part_dim.p_category
ORDER BY total_revenue DESC
LIMIT 100
