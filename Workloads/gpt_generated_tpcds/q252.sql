/*
  Total net loss by return reason, customer gender and hour of day across all return channels
*/
WITH store AS (
    SELECT
        sr.sr_reason_sk        AS reason_sk,
        sr.sr_return_time_sk   AS return_time_sk,
        sr.sr_net_loss         AS net_loss,
        sr.sr_return_quantity  AS return_qty,
        cd.cd_gender           AS gender
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
),
catalog AS (
    SELECT
        cr.cr_reason_sk        AS reason_sk,
        cr.cr_returned_time_sk AS return_time_sk,
        cr.cr_net_loss         AS net_loss,
        cr.cr_return_quantity  AS return_qty,
        cd.cd_gender           AS gender
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
),
web AS (
    SELECT
        wr.wr_reason_sk        AS reason_sk,
        wr.wr_returned_time_sk AS return_time_sk,
        wr.wr_net_loss         AS net_loss,
        wr.wr_return_quantity  AS return_qty,
        cd.cd_gender           AS gender
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
),
combined AS (
    SELECT reason_sk, return_time_sk, net_loss, return_qty, gender FROM store
    UNION ALL
    SELECT reason_sk, return_time_sk, net_loss, return_qty, gender FROM catalog
    UNION ALL
    SELECT reason_sk, return_time_sk, net_loss, return_qty, gender FROM web
)
SELECT
    r.r_reason_desc,
    c.gender,
    t.t_hour,
    SUM(c.net_loss)            AS total_net_loss,
    SUM(c.return_qty)          AS total_return_quantity,
    COUNT(*)                   AS total_returns
FROM combined c
JOIN reason r
    ON c.reason_sk = r.r_reason_sk
JOIN time_dim t
    ON c.return_time_sk = t.t_time_sk
GROUP BY r.r_reason_desc, c.gender, t.t_hour
ORDER BY total_net_loss DESC
LIMIT 100
