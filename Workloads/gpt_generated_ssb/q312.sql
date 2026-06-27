WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    od.order_year,
    cust.c_region,
    part.p_category,
    supp.s_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_dim od
JOIN customer cust
    ON od.lo_custkey = cust.c_custkey
JOIN part part
    ON od.lo_partkey = part.p_partkey
JOIN supplier supp
    ON od.lo_suppkey = supp.s_suppkey
WHERE od.order_year BETWEEN '1995' AND '1996'
GROUP BY od.order_year, cust.c_region, part.p_category, supp.s_region
ORDER BY od.order_year, cust.c_region, part.p_category, supp.s_region
