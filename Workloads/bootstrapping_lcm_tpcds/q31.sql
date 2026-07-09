WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        ws.web_site_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name, ws.web_site_id
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_name,
    a.web_site_id,
    a.total_sales,
    a.total_profit,
    a.total_return_amount,
    a.net_sales,
    a.distinct_tickets,
    a.avg_sales_price,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.net_sales DESC) AS sales_rank
FROM aggregated a
WHERE a.net_sales IS NOT NULL
ORDER BY a.d_year, a.d_month_seq, sales_rank
LIMIT 100
