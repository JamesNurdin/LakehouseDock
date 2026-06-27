WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_ord.d_year,
        d_ord.d_month,
        d_ord.d_date AS order_date,
        d_com.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_ord ON CAST(lo.lo_orderdate AS varchar) = d_ord.d_datekey
    JOIN dim_date d_com ON CAST(lo.lo_commitdate AS varchar) = d_com.d_datekey
    WHERE CAST(d_ord.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region AS cust_region,
    c.c_nation AS cust_nation,
    p.p_category,
    p.p_brand1,
    s.s_region AS supplier_region,
    lo_dates.d_year,
    lo_dates.d_month,
    SUM(lo_dates.lo_extendedprice * (1 - lo_dates.lo_discount / 100.0)) AS net_sales,
    SUM(lo_dates.lo_quantity) AS total_quantity,
    AVG(lo_dates.lo_discount) AS avg_discount,
    SUM(lo_dates.lo_revenue - lo_dates.lo_supplycost) AS profit
FROM lo_dates
JOIN customer c ON lo_dates.lo_custkey = c.c_custkey
JOIN part p ON lo_dates.lo_partkey = p.p_partkey
JOIN supplier s ON lo_dates.lo_suppkey = s.s_suppkey
WHERE s.s_region = 'ASIA'
GROUP BY
    c.c_region,
    c.c_nation,
    p.p_category,
    p.p_brand1,
    s.s_region,
    lo_dates.d_year,
    lo_dates.d_month
HAVING SUM(lo_dates.lo_extendedprice * (1 - lo_dates.lo_discount / 100.0)) > 1000000
ORDER BY profit DESC
LIMIT 20
