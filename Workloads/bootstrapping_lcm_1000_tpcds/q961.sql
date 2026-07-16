WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_date,
        d.d_year,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT cr.cr_order_number) AS return_transactions,
        CASE 
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
            ELSE SUM(cr.cr_return_amount) / SUM(ss.ss_ext_sales_price)
        END AS return_to_sales_ratio
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_date,
        d.d_year,
        t.t_hour
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.d_date,
    agg.d_year,
    agg.t_hour,
    agg.total_sales,
    agg.total_profit,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.sales_transactions,
    agg.return_transactions,
    agg.return_to_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.return_to_sales_ratio DESC) AS rank_within_year
FROM agg
ORDER BY agg.return_to_sales_ratio DESC
LIMIT 100
