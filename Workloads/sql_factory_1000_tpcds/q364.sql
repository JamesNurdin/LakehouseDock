WITH cust_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
cum_profit AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        cd_gender,
        cd_education_status,
        SUM(ss_net_profit) OVER (PARTITION BY ss_customer_sk ORDER BY ss_sold_date_sk
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit,
        SUM(ss_ext_sales_price) OVER (PARTITION BY ss_customer_sk ORDER BY ss_sold_date_sk
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
    FROM cust_sales
),
latest_cust AS (
    SELECT
        ss_customer_sk,
        cd_gender,
        cd_education_status,
        cum_profit,
        cum_sales,
        CASE WHEN cum_profit > 5000 THEN 'High Profit' ELSE 'Standard Profit' END AS profit_category,
        RANK() OVER (PARTITION BY cd_gender ORDER BY cum_profit DESC) AS profit_rank_by_gender
    FROM cum_profit
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    lc.cd_gender,
    lc.cd_education_status,
    lc.cum_profit,
    lc.cum_sales,
    lc.profit_category,
    lc.profit_rank_by_gender
FROM latest_cust lc
JOIN customer c ON lc.ss_customer_sk = c.c_customer_sk
ORDER BY lc.profit_rank_by_gender
LIMIT 10
