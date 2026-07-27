WITH sales_by_gender AS (
    SELECT
        cd.cd_gender,
        d.d_day_name,
        CONCAT(cd.cd_gender, '_', d.d_day_name) AS gender_day,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_day_name LIKE 'S%'
      AND regexp_like(cd.cd_credit_rating, '^A[0-9]')
    GROUP BY cd.cd_gender, d.d_day_name, CONCAT(cd.cd_gender, '_', d.d_day_name)
)
SELECT
    sbg.cd_gender,
    sbg.gender_day,
    sbg.store_net_profit,
    sbg.web_net_profit,
    (sbg.store_net_profit + sbg.web_net_profit) AS total_gender_profit,
    (sbg.store_net_profit + sbg.web_net_profit) / (
        SELECT SUM(store_net_profit + web_net_profit) FROM sales_by_gender
    ) AS profit_share
FROM sales_by_gender sbg
WHERE sbg.store_net_profit > (
    SELECT AVG(store_net_profit) FROM sales_by_gender
)
ORDER BY total_gender_profit DESC
LIMIT 100
