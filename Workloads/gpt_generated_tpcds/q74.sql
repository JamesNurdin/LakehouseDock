WITH unified AS (
    -- Catalog sales (billing side)
    SELECT d.d_year AS d_year,
           d.d_month_seq AS d_month_seq,
           cd.cd_gender AS cd_gender,
           ca.ca_state AS ca_state,
           cs.cs_net_paid AS net_paid,
           0.0 AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Web sales (billing side)
    SELECT d.d_year,
           d.d_month_seq,
           cd.cd_gender,
           ca.ca_state,
           ws.ws_net_paid,
           0.0
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Store returns
    SELECT d.d_year,
           d.d_month_seq,
           cd.cd_gender,
           ca.ca_state,
           0.0,
           sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Web returns
    SELECT d.d_year,
           d.d_month_seq,
           cd.cd_gender,
           ca.ca_state,
           0.0,
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
)
SELECT d_year,
       d_month_seq,
       cd_gender AS gender,
       ca_state AS state,
       SUM(net_paid) AS total_sales,
       SUM(net_loss) AS total_returns,
       SUM(net_paid) - SUM(net_loss) AS net_profit
FROM unified
GROUP BY d_year, d_month_seq, cd_gender, ca_state
ORDER BY net_profit DESC
LIMIT 20
