WITH profit_by_store_hour AS (
    SELECT
        s.s_store_name,
        t.t_hour,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'A'
      AND t.t_shift = 'Afternoon'
    GROUP BY s.s_store_name, t.t_hour, cd.cd_gender, cd.cd_marital_status
)
SELECT
    s_store_name,
    t_hour,
    cd_gender,
    cd_marital_status,
    total_profit,
    total_sales,
    avg_discount,
    profit_rank
FROM (
    SELECT
        s_store_name,
        t_hour,
        cd_gender,
        cd_marital_status,
        total_profit,
        total_sales,
        avg_discount,
        RANK() OVER (PARTITION BY s_store_name ORDER BY total_profit DESC) AS profit_rank
    FROM profit_by_store_hour
    WHERE total_profit > 0
) ranked
WHERE profit_rank <= 3
ORDER BY s_store_name, profit_rank
