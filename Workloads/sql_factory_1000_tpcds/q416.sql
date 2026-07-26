WITH sales_daily AS (
    SELECT
        cs.cs_ship_mode_sk,
        d.cd_gender,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_profit) AS daily_sales_profit,
        SUM(cs.cs_ext_discount_amt) AS daily_discount
    FROM catalog_sales cs
    JOIN customer_demographics d
        ON cs.cs_ship_cdemo_sk = d.cd_demo_sk
    GROUP BY cs.cs_ship_mode_sk, d.cd_gender, cs.cs_sold_date_sk
),
returns_daily AS (
    SELECT
        cs.cs_ship_mode_sk,
        d.cd_gender,
        cs.cs_sold_date_sk,
        SUM(wr.wr_net_loss) AS daily_returns_loss
    FROM web_returns wr
    JOIN catalog_sales cs
        ON wr.wr_order_number = cs.cs_order_number
        AND wr.wr_item_sk = cs.cs_item_sk
    JOIN customer_demographics d
        ON wr.wr_returning_cdemo_sk = d.cd_demo_sk
    GROUP BY cs.cs_ship_mode_sk, d.cd_gender, cs.cs_sold_date_sk
),
combined_daily AS (
    SELECT
        s.cs_ship_mode_sk,
        s.cd_gender,
        s.cs_sold_date_sk,
        s.daily_sales_profit,
        COALESCE(r.daily_returns_loss, 0) AS daily_returns_loss,
        s.daily_sales_profit - COALESCE(r.daily_returns_loss, 0) AS net_daily_profit,
        s.daily_discount
    FROM sales_daily s
    LEFT JOIN returns_daily r
        ON s.cs_ship_mode_sk = r.cs_ship_mode_sk
        AND s.cd_gender = r.cd_gender
        AND s.cs_sold_date_sk = r.cs_sold_date_sk
)
SELECT
    sm.sm_ship_mode_id,
    cd_gender,
    cs_sold_date_sk,
    net_daily_profit,
    daily_discount,
    CASE WHEN net_daily_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY net_daily_profit DESC) AS profit_rank,
    NTILE(4) OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY net_daily_profit DESC) AS profit_quartile
FROM combined_daily cd
JOIN ship_mode sm
    ON cd.cs_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY sm.sm_ship_mode_id, profit_rank
LIMIT 50
