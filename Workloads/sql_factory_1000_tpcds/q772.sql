WITH combined AS (
    SELECT
        sr.sr_reason_sk AS reason_sk,
        cd.cd_gender AS gender,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        wr.wr_reason_sk,
        cd.cd_gender,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT
    r.r_reason_desc,
    c.gender,
    SUM(c.net_loss) AS total_net_loss,
    SUM(c.return_qty) AS total_return_qty,
    DENSE_RANK() OVER (PARTITION BY c.gender ORDER BY SUM(c.net_loss) DESC) AS rank_by_gender,
    CASE WHEN SUM(c.net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM combined c
JOIN reason r ON c.reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc, c.gender
ORDER BY c.gender, rank_by_gender
