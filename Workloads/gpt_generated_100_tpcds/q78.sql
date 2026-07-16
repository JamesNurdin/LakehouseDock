WITH channel_aggregates AS (
    -- Store sales profit
    SELECT ss.ss_cdemo_sk AS cd_demo_sk,
           SUM(ss.ss_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM store_sales ss
    GROUP BY ss.ss_cdemo_sk

    UNION ALL
    -- Catalog sales profit
    SELECT cs.cs_bill_cdemo_sk AS cd_demo_sk,
           SUM(cs.cs_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_cdemo_sk

    UNION ALL
    -- Web sales profit
    SELECT ws.ws_bill_cdemo_sk AS cd_demo_sk,
           SUM(ws.ws_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM web_sales ws
    GROUP BY ws.ws_bill_cdemo_sk

    UNION ALL
    -- Store returns loss
    SELECT sr.sr_cdemo_sk AS cd_demo_sk,
           CAST(0 AS decimal(7,2)) AS profit,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    GROUP BY sr.sr_cdemo_sk

    UNION ALL
    -- Catalog returns loss
    SELECT cr.cr_refunded_cdemo_sk AS cd_demo_sk,
           CAST(0 AS decimal(7,2)) AS profit,
           SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_cdemo_sk

    UNION ALL
    -- Web returns loss
    SELECT wr.wr_refunded_cdemo_sk AS cd_demo_sk,
           CAST(0 AS decimal(7,2)) AS profit,
           SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    GROUP BY wr.wr_refunded_cdemo_sk
),

demographic_totals AS (
    SELECT ca.cd_demo_sk,
           SUM(ca.profit) AS total_profit,
           SUM(ca.loss)   AS total_loss
    FROM channel_aggregates ca
    GROUP BY ca.cd_demo_sk
)
SELECT cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.cd_education_status,
       dt.total_profit,
       dt.total_loss,
       (dt.total_profit - dt.total_loss) AS net_contribution
FROM demographic_totals dt
JOIN customer_demographics cd ON dt.cd_demo_sk = cd.cd_demo_sk
ORDER BY net_contribution DESC
LIMIT 20
