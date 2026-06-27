WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
),
aggregated AS (
    SELECT
        oc.order_year,
        cust.c_region,
        SUM(oc.lo_revenue) AS total_revenue,
        SUM(oc.lo_supplycost) AS total_supplycost,
        AVG(date_diff('day', date(oc.order_date), date(oc.commit_date))) AS avg_lead_days,
        AVG(oc.lo_discount) AS avg_discount
    FROM order_commit oc
    JOIN customer cust
        ON oc.lo_custkey = cust.c_custkey
    JOIN part p
        ON oc.lo_partkey = p.p_partkey
    JOIN supplier s
        ON oc.lo_suppkey = s.s_suppkey
    WHERE oc.order_year BETWEEN '1995' AND '1997'
    GROUP BY oc.order_year, cust.c_region
)
SELECT
    agg.order_year,
    agg.c_region,
    agg.total_revenue,
    agg.total_supplycost,
    agg.total_revenue - agg.total_supplycost AS profit,
    (agg.total_revenue - agg.total_supplycost) / NULLIF(agg.total_revenue, 0) AS profit_ratio,
    agg.avg_lead_days,
    agg.avg_discount,
    RANK() OVER (PARTITION BY agg.order_year ORDER BY agg.total_revenue - agg.total_supplycost DESC) AS profit_rank
FROM aggregated agg
ORDER BY agg.order_year, profit_rank
