WITH ws_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
sr_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(ws.d_year, sr.d_year) AS year,
    COALESCE(ws.d_month_seq, sr.d_month_seq) AS month_seq,
    COALESCE(ws.cd_gender, sr.cd_gender) AS gender,
    COALESCE(ws.cd_marital_status, sr.cd_marital_status) AS marital_status,
    ws.total_web_profit,
    sr.total_store_loss,
    ws.web_orders,
    sr.store_returns,
    CASE WHEN sr.total_store_loss = 0 OR sr.total_store_loss IS NULL THEN NULL
         ELSE ws.total_web_profit / sr.total_store_loss END AS profit_loss_ratio
FROM ws_agg ws
FULL OUTER JOIN sr_agg sr
  ON ws.d_year = sr.d_year
 AND ws.d_month_seq = sr.d_month_seq
 AND ws.cd_gender = sr.cd_gender
 AND ws.cd_marital_status = sr.cd_marital_status
ORDER BY year, month_seq, gender, marital_status
