/*
  Revenue and order metrics by region, year, and part category –
  top 3 categories per region/year for the AUTOMOBILE market segment in 1997.
*/
WITH revenue_by_category AS (
    SELECT
        cust.c_region,
        date_dim.d_year,
        part.p_category,
        SUM(lo.lo_revenue)          AS total_revenue,
        SUM(lo.lo_extendedprice)    AS total_extendedprice,
        AVG(lo.lo_discount)         AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN dim_date date_dim
        ON CAST(date_dim.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    WHERE cust.c_mktsegment = 'AUTOMOBILE'
      AND date_dim.d_year = '1997'
    GROUP BY cust.c_region, date_dim.d_year, part.p_category
),
ranked_categories AS (
    SELECT
        c_region,
        d_year,
        p_category,
        total_revenue,
        total_extendedprice,
        avg_discount,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY c_region, d_year ORDER BY total_revenue DESC) AS rn
    FROM revenue_by_category
)
SELECT
    c_region AS region,
    d_year   AS year,
    p_category AS category,
    total_revenue,
    total_extendedprice,
    avg_discount,
    order_count
FROM ranked_categories
WHERE rn <= 3
ORDER BY c_region, d_year, rn
