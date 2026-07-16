WITH sales AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, cd.cd_gender
),
returns AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, cd.cd_gender
)
SELECT
    COALESCE(s.s_store_name, r.s_store_name) AS store_name,
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.d_month_seq, r.d_month_seq) AS month_seq,
    COALESCE(s.cd_gender, r.cd_gender) AS gender,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
    RANK() OVER (PARTITION BY COALESCE(s.d_year, r.d_year) ORDER BY COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank
FROM sales s
FULL OUTER JOIN returns r
    ON s.s_store_name = r.s_store_name
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.cd_gender = r.cd_gender
ORDER BY profit_rank
LIMIT 100
