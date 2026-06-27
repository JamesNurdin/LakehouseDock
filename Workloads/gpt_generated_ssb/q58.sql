WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_year,
        d_order.d_month,
        d_commit.d_holidayfl,
        cust.c_region,
        part.p_category,
        supp.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    WHERE d_order.d_year = '1995'
      AND d_commit.d_holidayfl = 'Y'
      AND cust.c_region = 'AMERICA'
      AND supp.s_region = 'ASIA'
      AND part.p_category = 'MFGR#1'
)
SELECT
    order_details.d_year,
    order_details.p_category,
    SUM(order_details.lo_revenue) AS total_revenue,
    SUM(order_details.lo_supplycost) AS total_supply_cost,
    SUM(order_details.lo_tax) AS total_tax,
    SUM(order_details.lo_revenue) - SUM(order_details.lo_supplycost) - SUM(order_details.lo_tax) AS profit,
    AVG(order_details.lo_discount) AS avg_discount,
    COUNT(*) AS order_line_count
FROM order_details
GROUP BY order_details.d_year, order_details.p_category
ORDER BY total_revenue DESC
