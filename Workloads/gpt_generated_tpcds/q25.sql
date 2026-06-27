WITH
    store_data AS (
        SELECT
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        GROUP BY cd.cd_gender, cd.cd_marital_status
    ),
    return_data AS (
        SELECT
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            SUM(sr.sr_return_amt_inc_tax) AS return_amt,
            SUM(sr.sr_net_loss) AS return_net_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        GROUP BY cd.cd_gender, cd.cd_marital_status
    ),
    web_data AS (
        SELECT
            cd.cd_gender AS gender,
            cd.cd_marital_status AS marital_status,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY cd.cd_gender, cd.cd_marital_status
    )
SELECT
    COALESCE(s.gender, r.gender, w.gender) AS gender,
    COALESCE(s.marital_status, r.marital_status, w.marital_status) AS marital_status,
    COALESCE(s.store_net_paid, 0) AS store_net_paid,
    COALESCE(w.web_net_paid, 0) AS web_net_paid,
    COALESCE(r.return_amt, 0) AS total_return_amount,
    COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.return_net_loss, 0) AS net_profit_after_returns,
    COALESCE(s.store_sales_cnt, 0) + COALESCE(w.web_sales_cnt, 0) AS total_sales_cnt,
    CAST(COALESCE(r.return_cnt, 0) AS double) / NULLIF(COALESCE(s.store_sales_cnt, 0), 0) AS store_return_rate,
    ROW_NUMBER() OVER (
        ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.return_net_loss, 0)) DESC
    ) AS profit_rank
FROM store_data s
FULL OUTER JOIN return_data r
    ON s.gender = r.gender AND s.marital_status = r.marital_status
FULL OUTER JOIN web_data w
    ON COALESCE(s.gender, r.gender) = w.gender
   AND COALESCE(s.marital_status, r.marital_status) = w.marital_status
ORDER BY net_profit_after_returns DESC
LIMIT 10
