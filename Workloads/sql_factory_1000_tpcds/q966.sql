WITH sales_by_week AS (
    SELECT
        d.d_year,
        d.d_week_seq,
        SUM(ss.ss_ext_sales_price) AS week_sales,
        SUM(ss.ss_quantity) AS week_units_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_year, d.d_week_seq
),
 returns_by_week AS (
    SELECT
        d.d_year,
        d.d_week_seq,
        SUM(sr.sr_net_loss) AS week_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_year, d.d_week_seq
),
 net_by_week AS (
    SELECT
        s.d_year,
        s.d_week_seq,
        s.week_sales,
        COALESCE(r.week_return_loss,0) AS week_return_loss,
        (s.week_sales - COALESCE(r.week_return_loss,0)) AS week_net_revenue,
        s.week_units_sold
    FROM sales_by_week s
    LEFT JOIN returns_by_week r ON s.d_year = r.d_year AND s.d_week_seq = r.d_week_seq
)
SELECT
    d_year,
    d_week_seq,
    week_sales,
    week_return_loss,
    week_net_revenue,
    week_units_sold,
    ROW_NUMBER() OVER (ORDER BY week_net_revenue DESC) AS revenue_rank,
    AVG(week_net_revenue) OVER (PARTITION BY d_year) AS avg_yearly_net
FROM net_by_week
WHERE d_week_seq BETWEEN 1 AND 5
ORDER BY d_week_seq
