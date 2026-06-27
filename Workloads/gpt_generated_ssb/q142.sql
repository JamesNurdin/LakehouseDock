WITH order_agg AS (
    SELECT
        dim.d_year,
        dim.d_month,
        dim.d_yearmonthnum,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date dim
        ON lo.lo_orderdate = CAST(dim.d_datekey AS integer)
    WHERE dim.d_year BETWEEN '1992' AND '1997'
    GROUP BY dim.d_year, dim.d_month, dim.d_yearmonthnum
)
SELECT
    d_year,
    d_month,
    d_yearmonthnum,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    SUM(total_profit) OVER (
        PARTITION BY d_year
        ORDER BY CAST(d_yearmonthnum AS integer)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_year_to_date
FROM order_agg
ORDER BY d_year, CAST(d_yearmonthnum AS integer)
