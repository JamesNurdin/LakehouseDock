WITH sales AS (
    SELECT
        td.t_hour AS hour,
        cd.cd_gender AS gender,
        cs.cs_net_profit AS net_value
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        td.t_hour,
        cd.cd_gender,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        td.t_hour,
        cd.cd_gender,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
returns AS (
    SELECT
        td.t_hour AS hour,
        cd.cd_gender AS gender,
        -cr.cr_net_loss AS net_value
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        td.t_hour,
        cd.cd_gender,
        -sr.sr_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        td.t_hour,
        cd.cd_gender,
        -wr.wr_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT
    hour,
    gender,
    sum(net_value) AS net_contribution,
    sum(CASE WHEN net_value > 0 THEN net_value ELSE 0 END) AS total_profit,
    sum(CASE WHEN net_value < 0 THEN -net_value ELSE 0 END) AS total_loss,
    count(*) AS transaction_cnt
FROM (
    SELECT hour, gender, net_value FROM sales
    UNION ALL
    SELECT hour, gender, net_value FROM returns
) combined
GROUP BY hour, gender
ORDER BY hour, gender
