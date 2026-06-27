WITH revenue_by_year_cust_supp_part AS (
    SELECT
        d.d_year,
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
      ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
)
SELECT
    d_year,
    cust_region,
    supp_region,
    part_category,
    total_revenue,
    total_profit,
    avg_discount,
    order_cnt
FROM revenue_by_year_cust_supp_part
ORDER BY d_year, cust_region, supp_region, part_category
