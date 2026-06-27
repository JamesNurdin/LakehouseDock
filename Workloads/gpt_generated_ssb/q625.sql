WITH lo_detail AS (
    SELECT
        lineorder.lo_orderkey,
        lineorder.lo_linenumber,
        lineorder.lo_custkey,
        lineorder.lo_partkey,
        lineorder.lo_suppkey,
        lineorder.lo_orderdate,
        lineorder.lo_commitdate,
        lineorder.lo_quantity,
        lineorder.lo_extendedprice,
        lineorder.lo_ordertotalprice,
        lineorder.lo_discount,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_tax,
        lineorder.lo_shipmode,
        d_order.d_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        customer.c_region,
        part.p_category
    FROM lineorder
    JOIN dim_date AS d_order
        ON CAST(lineorder.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date AS d_commit
        ON CAST(lineorder.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE d_order.d_year = '1995'
      AND part.p_category = 'MFGR#12'
)
SELECT
    d_year AS order_year,
    c_region AS region,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_days
FROM lo_detail
GROUP BY d_year, c_region
ORDER BY total_revenue DESC
LIMIT 10
