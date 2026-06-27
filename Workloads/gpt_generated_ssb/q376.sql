WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_tax
    FROM lineorder lo
    WHERE lo.lo_quantity > 0
)
SELECT
    od.d_year,
    cust.c_region,
    p.p_category,
    COUNT(*) AS order_count,
    SUM(odet.lo_revenue) AS total_revenue,
    SUM(odet.lo_revenue - odet.lo_supplycost) AS total_profit,
    AVG(date_diff('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_shipping_delay_days
FROM order_details odet
JOIN dim_date od
    ON CAST(odet.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
    ON CAST(odet.lo_commitdate AS VARCHAR) = cd.d_datekey
JOIN customer cust
    ON odet.lo_custkey = cust.c_custkey
JOIN part p
    ON odet.lo_partkey = p.p_partkey
JOIN supplier sup
    ON odet.lo_suppkey = sup.s_suppkey
WHERE od.d_year BETWEEN '1992' AND '1997'
GROUP BY od.d_year, cust.c_region, p.p_category
ORDER BY od.d_year, cust.c_region, p.p_category
