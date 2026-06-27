WITH store_agg AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUM(ss.ss_net_paid) AS store_net_paid,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
web_agg AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_paid) AS web_net_paid,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
return_agg AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUM(wr.wr_net_loss) AS return_net_loss,
           SUM(wr.wr_return_quantity) AS return_quantity
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT COALESCE(s.cd_gender, w.cd_gender, r.cd_gender) AS gender,
       COALESCE(s.cd_marital_status, w.cd_marital_status, r.cd_marital_status) AS marital_status,
       COALESCE(s.store_net_paid, 0) AS store_net_paid,
       COALESCE(s.store_net_profit, 0) AS store_net_profit,
       COALESCE(w.web_net_paid, 0) AS web_net_paid,
       COALESCE(w.web_net_profit, 0) AS web_net_profit,
       COALESCE(r.return_net_loss, 0) AS return_net_loss,
       (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.return_net_loss, 0)) AS total_net
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.cd_gender = w.cd_gender
   AND s.cd_marital_status = w.cd_marital_status
FULL OUTER JOIN return_agg r
    ON COALESCE(s.cd_gender, w.cd_gender) = r.cd_gender
   AND COALESCE(s.cd_marital_status, w.cd_marital_status) = r.cd_marital_status
ORDER BY total_net DESC
LIMIT 20
