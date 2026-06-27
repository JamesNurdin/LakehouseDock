WITH sales_agg AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
    UNION ALL
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
    UNION ALL
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
    UNION ALL
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
    UNION ALL
    SELECT
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    s.ca_state,
    s.cd_gender,
    s.hd_income_band_sk,
    SUM(s.net_paid) AS total_sales_net_paid,
    SUM(COALESCE(r.net_loss, 0)) AS total_returns_net_loss,
    SUM(s.net_paid) - SUM(COALESCE(r.net_loss, 0)) AS net_revenue,
    SUM(s.net_profit) AS total_sales_net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ca_state = r.ca_state
   AND s.cd_gender = r.cd_gender
   AND s.hd_income_band_sk = r.hd_income_band_sk
GROUP BY s.ca_state, s.cd_gender, s.hd_income_band_sk
ORDER BY net_revenue DESC
LIMIT 20
