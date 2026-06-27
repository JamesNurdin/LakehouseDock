WITH catalog_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           cd.cd_gender AS gender,
           SUM(cs.cs_quantity) AS catalog_quantity,
           SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           cd.cd_gender AS gender,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
web_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           cd.cd_gender AS gender,
           SUM(wr.wr_return_quantity) AS return_quantity,
           SUM(wr.wr_net_loss) AS returns_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd.cd_gender
),
combined AS (
    SELECT
        COALESCE(cs.year, ws.year, wr.year) AS year,
        COALESCE(cs.month_seq, ws.month_seq, wr.month_seq) AS month_seq,
        COALESCE(cs.category, ws.category, wr.category) AS category,
        COALESCE(cs.gender, ws.gender, wr.gender) AS gender,
        COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
        COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(wr.returns_loss, 0) AS net_profit_after_returns,
        COALESCE(wr.return_quantity, 0) AS return_quantity
    FROM catalog_sales_agg cs
    FULL OUTER JOIN web_sales_agg ws
        ON cs.year = ws.year
       AND cs.month_seq = ws.month_seq
       AND cs.category = ws.category
       AND cs.gender = ws.gender
    FULL OUTER JOIN web_returns_agg wr
        ON COALESCE(cs.year, ws.year) = wr.year
       AND COALESCE(cs.month_seq, ws.month_seq) = wr.month_seq
       AND COALESCE(cs.category, ws.category) = wr.category
       AND COALESCE(cs.gender, ws.gender) = wr.gender
)
SELECT
    year,
    month_seq,
    category,
    gender,
    total_quantity,
    net_profit_after_returns,
    return_quantity,
    SUM(net_profit_after_returns) OVER (
        PARTITION BY category, gender
        ORDER BY year, month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_profit
FROM combined
ORDER BY year, month_seq, category, gender
