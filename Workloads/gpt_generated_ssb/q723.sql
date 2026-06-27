WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_orderpriority
    FROM lineorder
    WHERE lo_quantity > 10
      AND lo_discount BETWEEN 5 AND 10
      AND lo_orderpriority IN ('1-URGENT', '2-HIGH')
),
customer_part AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_orderpriority,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1
    FROM filtered_orders lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
),
agg AS (
    SELECT
        c_region,
        p_category,
        sum(lo_revenue) AS total_revenue,
        sum(lo_extendedprice) AS total_extended_price,
        sum(lo_quantity) AS total_quantity,
        avg(lo_discount) AS avg_discount
    FROM customer_part
    GROUP BY c_region, p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_extended_price,
    total_quantity,
    avg_discount,
    total_revenue * 100.0 / sum(total_revenue) OVER () AS revenue_pct
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
