WITH profit_line AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_shipmode,
        lo_extendedprice,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_discount,
        (lo_revenue - lo_supplycost - lo_tax) AS profit
    FROM lineorder
),
joined AS (
    SELECT
        d.d_year,
        d.d_month,
        p.lo_shipmode,
        p.lo_extendedprice,
        p.lo_revenue,
        p.profit,
        p.lo_discount
    FROM profit_line p
    JOIN dim_date d
      ON CAST(d.d_datekey AS INTEGER) = p.lo_orderdate
    WHERE d.d_year BETWEEN '1992' AND '1997'
),
aggregated AS (
    SELECT
        d_year,
        d_month,
        lo_shipmode,
        SUM(lo_extendedprice) AS total_extended_price,
        SUM(lo_revenue) AS total_revenue,
        SUM(profit) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM joined
    GROUP BY d_year, d_month, lo_shipmode
)
SELECT
    d_year,
    d_month,
    lo_shipmode,
    total_extended_price,
    total_revenue,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_by_year
FROM aggregated
ORDER BY d_year, d_month, profit_rank_by_year
