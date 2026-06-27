WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_revenue,
        dim.d_year AS order_year,
        dim.d_date AS order_date,
        cust.c_region AS cust_region,
        supp.s_region AS supp_region,
        part.p_category AS part_category,
        part.p_brand1 AS part_brand,
        part.p_type AS part_type
    FROM lineorder lo
    JOIN dim_date dim
        ON CAST(dim.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    JOIN part part
        ON lo.lo_partkey = part.p_partkey
    WHERE dim.d_year = '1993'
      AND part.p_category = 'MFGR#1'
)
SELECT
    cust_region,
    supp_region,
    order_year,
    part_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_details
GROUP BY cust_region, supp_region, order_year, part_category
ORDER BY total_revenue DESC
LIMIT 10
