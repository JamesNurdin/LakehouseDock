WITH order_commit AS (
    SELECT
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od_order.d_date AS order_date,
        od_order.d_year AS order_year,
        od_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od_order
        ON CAST(lo.lo_orderdate AS varchar) = od_order.d_datekey
    JOIN dim_date od_commit
        ON CAST(lo.lo_commitdate AS varchar) = od_commit.d_datekey
    WHERE od_order.d_year = '1997'
)
SELECT
    s.s_region,
    p.p_category,
    COUNT(*) AS order_cnt,
    AVG(date_diff('day', CAST(oc.order_date AS date), CAST(oc.commit_date AS date))) AS avg_lead_days
FROM order_commit oc
JOIN supplier s
    ON oc.lo_suppkey = s.s_suppkey
JOIN part p
    ON oc.lo_partkey = p.p_partkey
GROUP BY s.s_region, p.p_category
ORDER BY avg_lead_days DESC
LIMIT 20
