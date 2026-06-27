WITH lo_supp AS (
    SELECT
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_shipmode
    FROM lineorder lo
    WHERE lo.lo_quantity > 0
)
SELECT
    s.s_region,
    lo_supp.lo_shipmode,
    SUM(lo_supp.lo_revenue) AS total_revenue,
    AVG(lo_supp.lo_discount) AS avg_discount,
    SUM(lo_supp.lo_extendedprice) AS total_extendedprice,
    COUNT(*) AS order_count
FROM lo_supp
JOIN supplier s
    ON lo_supp.lo_suppkey = s.s_suppkey
GROUP BY
    s.s_region,
    lo_supp.lo_shipmode
ORDER BY total_revenue DESC
LIMIT 10
