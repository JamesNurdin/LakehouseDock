WITH lo AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_tax
    FROM lineorder
)
SELECT
    d_order.d_year AS order_year,
    d_commit.d_year AS commit_year,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
WHERE d_order.d_year = '1994'
GROUP BY d_order.d_year, d_commit.d_year
ORDER BY d_order.d_year, d_commit.d_year
