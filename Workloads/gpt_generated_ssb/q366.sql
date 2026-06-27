WITH filtered_customer AS (
    SELECT
        c_custkey,
        c_region
    FROM customer
    WHERE c_region IN ('AMERICA', 'ASIA')
),
filtered_part AS (
    SELECT
        p_partkey,
        p_category
    FROM part
    WHERE p_category IN ('MFGR#1', 'MFGR#2')
)
SELECT
    fc.c_region,
    fp.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    COUNT(DISTINCT lo.lo_custkey) AS distinct_customers
FROM lineorder lo
JOIN filtered_customer fc
    ON lo.lo_custkey = fc.c_custkey
JOIN filtered_part fp
    ON lo.lo_partkey = fp.p_partkey
GROUP BY fc.c_region, fp.p_category
ORDER BY total_revenue DESC
LIMIT 10
