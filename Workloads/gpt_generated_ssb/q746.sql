WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_date      AS order_date,
        od.d_year      AS order_year,
        cd.d_date      AS commit_date,
        cd.d_year      AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
),
agg AS (
    SELECT
        oc.order_year,
        s.s_region,
        p.p_category,
        COUNT(DISTINCT oc.lo_orderkey)                         AS num_orders,
        SUM(oc.lo_revenue)                                     AS total_revenue,
        SUM(oc.lo_revenue - oc.lo_supplycost)                  AS total_profit,
        AVG(date_diff('day', date(oc.order_date), date(oc.commit_date))) AS avg_days_to_commit
    FROM order_commit oc
    JOIN customer c ON oc.lo_custkey = c.c_custkey
    JOIN supplier s ON oc.lo_suppkey = s.s_suppkey
    JOIN part p     ON oc.lo_partkey = p.p_partkey
    WHERE oc.order_year = '1995'
      AND s.s_region = 'AMERICA'
      AND p.p_category = 'MFGR#1'
    GROUP BY oc.order_year, s.s_region, p.p_category
)
SELECT
    order_year,
    s_region,
    p_category,
    num_orders,
    total_revenue,
    total_profit,
    avg_days_to_commit,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
