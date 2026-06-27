WITH sales_agg AS (
    -- Sales side: store, catalog and web
    SELECT cd.cd_gender AS gender,
           cd.cd_marital_status AS marital_status,
           SUM(ss.ss_net_profit) AS profit,
           0 AS loss
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUM(cs.cs_net_profit),
           0
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_profit),
           0
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),

returns_agg AS (
    -- Returns side: store, catalog and web
    SELECT cd.cd_gender AS gender,
           cd.cd_marital_status AS marital_status,
           0 AS profit,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT cd.cd_gender,
           cd.cd_marital_status,
           0,
           SUM(cr.cr_net_loss)
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT cd.cd_gender,
           cd.cd_marital_status,
           0,
           SUM(wr.wr_net_loss)
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),

combined AS (
    SELECT gender,
           marital_status,
           SUM(profit) AS total_profit,
           SUM(loss)   AS total_loss
    FROM (
        SELECT * FROM sales_agg
        UNION ALL
        SELECT * FROM returns_agg
    ) u
    GROUP BY gender, marital_status
)
SELECT gender,
       marital_status,
       total_profit,
       total_loss,
       total_profit - total_loss AS net_contribution
FROM combined
ORDER BY net_contribution DESC
LIMIT 20
