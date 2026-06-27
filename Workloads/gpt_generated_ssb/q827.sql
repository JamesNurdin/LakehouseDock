WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_tax,
        cust.c_region AS cust_region,
        cust.c_nation AS cust_nation,
        cust.c_mktsegment,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_commit.d_year AS commit_year,
        part.p_category,
        part.p_brand1,
        part.p_color,
        part.p_type,
        part.p_size,
        part.p_container,
        supp.s_region AS supp_region,
        supp.s_nation AS supp_nation
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
)
SELECT
    od.cust_region,
    od.p_category,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_extendedprice * od.lo_discount / 100) AS total_discount_amount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders,
    AVG(od.lo_discount) AS avg_discount,
    MIN(od.lo_tax) AS min_tax,
    MAX(od.lo_tax) AS max_tax
FROM order_details od
WHERE od.order_year = '1997'
GROUP BY od.cust_region, od.p_category, od.order_year
ORDER BY total_revenue DESC
LIMIT 20
