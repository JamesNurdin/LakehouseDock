WITH region_sales AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_net_price,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    c_region,
    c_mktsegment,
    total_extendedprice,
    total_net_price,
    total_quantity,
    avg_discount,
    distinct_orders,
    RANK() OVER (ORDER BY total_net_price DESC) AS region_sales_rank
FROM region_sales
ORDER BY region_sales_rank
LIMIT 10
