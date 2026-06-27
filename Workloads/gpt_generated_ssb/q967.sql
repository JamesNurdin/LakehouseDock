WITH lo_enriched AS (
    SELECT
        lo_orderkey,
        lo_partkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_discount,
        (lo_revenue - lo_supplycost - lo_tax) AS profit
    FROM lineorder
)
SELECT
    d_order.d_year AS order_year,
    p.p_category,
    p.p_brand1,
    SUM(lo_enriched.lo_revenue) AS total_revenue,
    SUM(lo_enriched.profit) AS total_profit,
    AVG(lo_enriched.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(d_order.d_date AS DATE), CAST(d_commit.d_date AS DATE))) AS avg_lead_time_days,
    COUNT(DISTINCT lo_enriched.lo_orderkey) AS distinct_orders
FROM lo_enriched
JOIN dim_date AS d_order
    ON CAST(lo_enriched.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date AS d_commit
    ON CAST(lo_enriched.lo_commitdate AS varchar) = d_commit.d_datekey
JOIN part AS p
    ON lo_enriched.lo_partkey = p.p_partkey
WHERE d_order.d_year = '1995'
  AND d_commit.d_year = '1995'
GROUP BY d_order.d_year, p.p_category, p.p_brand1
ORDER BY total_revenue DESC
LIMIT 100
