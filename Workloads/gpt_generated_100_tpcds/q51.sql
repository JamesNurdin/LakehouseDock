WITH monthly_store_sales AS (
    SELECT
        s.s_store_name,
        d_sale.d_year,
        d_sale.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_net_paid), 0) AS net_profit_margin
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_sale.d_year = 2001
      AND (s.s_closed_date_sk IS NULL OR d_sale.d_date <= d_closed.d_date)
    GROUP BY s.s_store_name, d_sale.d_year, d_sale.d_month_seq
)
SELECT
    ms.s_store_name,
    ms.d_year,
    ms.d_month_seq,
    ms.total_net_paid,
    ms.total_net_profit,
    ms.total_quantity,
    ms.net_profit_margin,
    RANK() OVER (PARTITION BY ms.d_year, ms.d_month_seq ORDER BY ms.total_net_profit DESC) AS profit_rank
FROM monthly_store_sales ms
ORDER BY ms.d_year, ms.d_month_seq, profit_rank
