WITH cs_agg AS (
    SELECT cs.cs_bill_hdemo_sk AS hd_demo_sk,
           SUM(cs.cs_net_profit) AS total_cs_net_profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY cs.cs_bill_hdemo_sk
),
ws_agg AS (
    SELECT ws.ws_bill_hdemo_sk AS hd_demo_sk,
           SUM(ws.ws_net_profit) AS total_ws_net_profit
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY ws.ws_bill_hdemo_sk
),
sr_agg AS (
    SELECT sr.sr_hdemo_sk AS hd_demo_sk,
           SUM(sr.sr_net_loss) AS total_sr_net_loss
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY sr.sr_hdemo_sk
),
wr_agg AS (
    SELECT wr.wr_refunded_hdemo_sk AS hd_demo_sk,
           SUM(wr.wr_net_loss) AS total_wr_net_loss
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY wr.wr_refunded_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    SUM(
        COALESCE(cs.total_cs_net_profit, 0) +
        COALESCE(ws.total_ws_net_profit, 0) -
        COALESCE(sr.total_sr_net_loss, 0) -
        COALESCE(wr.total_wr_net_loss, 0)
    ) AS net_contribution
FROM household_demographics hd
LEFT JOIN cs_agg cs ON cs.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN ws_agg ws ON ws.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN sr_agg sr ON sr.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN wr_agg wr ON wr.hd_demo_sk = hd.hd_demo_sk
GROUP BY hd.hd_buy_potential
ORDER BY net_contribution DESC
