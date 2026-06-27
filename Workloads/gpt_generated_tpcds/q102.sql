WITH store_quarter_sales AS (
    SELECT
        s.s_store_id,
        d.d_quarter_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
    GROUP BY s.s_store_id, d.d_quarter_name
)
SELECT
    s_store_id,
    d_quarter_name,
    total_net_paid,
    total_net_profit,
    sales_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM store_quarter_sales
ORDER BY profit_rank
