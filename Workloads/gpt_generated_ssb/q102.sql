-- Total revenue, profit, quantity and average lead time by year, customer region, supplier region, and part category
WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        CAST(od.d_datekey AS INTEGER) AS order_datekey,
        od.d_year,
        od.d_date AS order_date_str
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
),
commit_dim AS (
    SELECT
        lo.lo_orderkey,
        CAST(cd.d_datekey AS INTEGER) AS commit_datekey,
        cd.d_date AS commit_date_str
    FROM lineorder lo
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
)
SELECT
    od.d_year AS order_year,
    cust.c_region AS customer_region,
    supp.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(od.lo_extendedprice) AS total_extended_price,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(date_diff('day', CAST(od.order_date_str AS DATE), CAST(cd.commit_date_str AS DATE))) AS avg_lead_days
FROM order_dim od
JOIN commit_dim cd
    ON od.lo_orderkey = cd.lo_orderkey
JOIN customer cust
    ON od.lo_custkey = cust.c_custkey
JOIN supplier supp
    ON od.lo_suppkey = supp.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE CAST(od.order_date_str AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY od.d_year, cust.c_region, supp.s_region, p.p_category
ORDER BY od.d_year, total_revenue DESC
