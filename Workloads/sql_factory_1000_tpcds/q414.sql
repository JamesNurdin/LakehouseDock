WITH sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk AS ship_mode_sk,
        d.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales cs
    JOIN customer_demographics d
        ON cs.cs_ship_cdemo_sk = d.cd_demo_sk
    GROUP BY cs.cs_ship_mode_sk, d.cd_gender
),
returns_agg AS (
    SELECT
        cs.cs_ship_mode_sk AS ship_mode_sk,
        d.cd_gender AS gender,
        SUM(wr.wr_net_loss) AS total_returns_loss,
        SUM(wr.wr_return_amt) AS total_returns_amount
    FROM web_returns wr
    JOIN catalog_sales cs
        ON wr.wr_order_number = cs.cs_order_number
        AND wr.wr_item_sk = cs.cs_item_sk
    JOIN customer_demographics d
        ON wr.wr_returning_cdemo_sk = d.cd_demo_sk
    GROUP BY cs.cs_ship_mode_sk, d.cd_gender
)
SELECT
    sm.sm_ship_mode_id,
    s.gender,
    s.total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales_profit - COALESCE(r.total_returns_loss, 0) AS net_profit,
    CASE
        WHEN s.total_sales_profit - COALESCE(r.total_returns_loss, 0) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_flag,
    RANK() OVER (ORDER BY s.total_sales_profit - COALESCE(r.total_returns_loss, 0) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ship_mode_sk = r.ship_mode_sk
    AND s.gender = r.gender
JOIN ship_mode sm
    ON s.ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY profit_rank
LIMIT 10
