WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy  AS month,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender, cd.cd_marital_status
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy  AS month,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.month, r.month) AS month,
    COALESCE(s.gender, r.gender) AS gender,
    COALESCE(s.marital_status, r.marital_status) AS marital_status,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(r.total_loss, 0) AS total_loss,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.year = r.year
 AND s.month = r.month
 AND s.gender = r.gender
 AND s.marital_status = r.marital_status
ORDER BY year, month, gender, marital_status
