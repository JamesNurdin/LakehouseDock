WITH cust_agg AS (
    SELECT
        lo_custkey,
        sum(lo_revenue) AS total_revenue,
        sum(lo_quantity) AS total_quantity,
        avg(lo_discount) AS avg_discount,
        count(distinct lo_orderkey) AS order_cnt
    FROM lineorder
    GROUP BY lo_custkey
),
ranked_customers AS (
    SELECT
        c.c_name,
        c.c_region,
        c.c_mktsegment,
        ca.total_revenue,
        ca.total_quantity,
        ca.avg_discount,
        ca.order_cnt,
        rank() OVER (PARTITION BY c.c_region ORDER BY ca.total_revenue DESC) AS region_rank
    FROM cust_agg ca
    JOIN customer c
        ON ca.lo_custkey = c.c_custkey
)
SELECT
    c_name,
    c_region,
    c_mktsegment,
    total_revenue,
    total_quantity,
    avg_discount,
    order_cnt,
    region_rank
FROM ranked_customers
WHERE region_rank <= 10
ORDER BY c_region, region_rank
