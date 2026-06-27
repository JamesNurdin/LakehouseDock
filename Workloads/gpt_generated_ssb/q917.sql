WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        CAST(d.d_year AS integer) AS order_year,
        cust.c_region AS cust_region,
        sup.s_region AS supp_region,
        p.p_category AS part_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier sup
        ON lo.lo_suppkey = sup.s_suppkey
    WHERE d.d_year BETWEEN '1993' AND '1997'
)
SELECT
    order_year,
    cust_region,
    supp_region,
    part_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
GROUP BY order_year, cust_region, supp_region, part_category
ORDER BY total_profit DESC
LIMIT 10
