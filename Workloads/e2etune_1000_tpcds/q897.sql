WITH store_agg AS (
    SELECT
        i.i_category,
        d.d_quarter_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender = 'F'
      AND d.d_year = 2022
    GROUP BY i.i_category, d.d_quarter_name, cd.cd_gender, cd.cd_marital_status
),

web_agg AS (
    SELECT
        i.i_category,
        d.d_quarter_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender = 'F'
      AND d.d_year = 2022
    GROUP BY i.i_category, d.d_quarter_name, cd.cd_gender, cd.cd_marital_status
),

combined AS (
    SELECT i_category, d_quarter_name, cd_gender, cd_marital_status, total_net_profit, sales_count
    FROM store_agg
    UNION ALL
    SELECT i_category, d_quarter_name, cd_gender, cd_marital_status, total_net_profit, sales_count
    FROM web_agg
)

SELECT
    i_category,
    d_quarter_name,
    cd_gender,
    cd_marital_status,
    SUM(total_net_profit) AS quarter_category_profit,
    SUM(sales_count) AS total_sales,
    RANK() OVER (PARTITION BY d_quarter_name ORDER BY SUM(total_net_profit) DESC) AS profit_rank
FROM combined
GROUP BY i_category, d_quarter_name, cd_gender, cd_marital_status
HAVING SUM(total_net_profit) > 0
ORDER BY d_quarter_name, profit_rank
