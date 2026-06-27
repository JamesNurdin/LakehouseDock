WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_discount,
        c.c_region      AS cust_region,
        s.s_region      AS supp_region,
        p.p_category,
        d_order.d_year,
        d_order.d_date  AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d_order ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    od.cust_region,
    od.supp_region,
    od.p_category,
    od.d_year,
    COUNT(DISTINCT od.lo_orderkey)                         AS order_cnt,
    SUM(od.lo_revenue)                                     AS total_revenue,
    AVG(od.lo_discount)                                    AS avg_discount,
    AVG(date_diff('day', date(od.order_date), date(od.commit_date))) AS avg_lead_time_days
FROM order_details od
WHERE od.d_year BETWEEN '1995' AND '1998'
GROUP BY
    od.cust_region,
    od.supp_region,
    od.p_category,
    od.d_year
ORDER BY total_revenue DESC
LIMIT 20
