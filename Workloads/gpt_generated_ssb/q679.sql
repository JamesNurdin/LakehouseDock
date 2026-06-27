WITH cust_part_rev AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity > 5
    GROUP BY c.c_custkey, c.c_name, c.c_region, p.p_brand1
)
SELECT
    cpr.c_region,
    cpr.p_brand1,
    cpr.c_name,
    cpr.total_revenue,
    cpr.total_quantity,
    cpr.avg_discount,
    cpr.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cpr.c_region ORDER BY cpr.total_revenue DESC) AS region_rank
FROM cust_part_rev cpr
WHERE cpr.total_revenue > 1000000
ORDER BY cpr.c_region, region_rank
LIMIT 100
