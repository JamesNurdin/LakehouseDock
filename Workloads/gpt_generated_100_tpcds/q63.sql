WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq AS month,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.month,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    sa.total_sales - COALESCE(ra.total_returns, 0) AS net_revenue,
    sa.total_profit,
    sa.total_discount / NULLIF(sa.total_quantity, 0) AS avg_discount_per_item,
    sa.distinct_tickets,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.distinct_return_tickets, 0) AS distinct_return_tickets
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_name = ra.s_store_name
    AND sa.d_year = ra.d_year
    AND sa.month = ra.month
ORDER BY net_revenue DESC
LIMIT 20
