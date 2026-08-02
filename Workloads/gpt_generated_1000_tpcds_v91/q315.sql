WITH high_spenders AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate >= 5000
)
SELECT
    channel,
    c_customer_id,
    total_sales_amount,
    total_profit,
    total_returns_loss,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_profit DESC) AS profit_rank,
    avg_profit
FROM (
    SELECT
        'Catalog' AS channel,
        hs.c_customer_id,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_returns_loss,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_profit
    FROM catalog_sales cs
    JOIN high_spenders hs
        ON cs.cs_bill_customer_sk = hs.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    GROUP BY hs.c_customer_id

    UNION DISTINCT

    SELECT
        'Web' AS channel,
        hs.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_returns_loss,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
        (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_profit
    FROM web_sales ws
    JOIN high_spenders hs
        ON ws.ws_bill_customer_sk = hs.c_customer_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    GROUP BY hs.c_customer_id
) AS combined
ORDER BY net_profit DESC, channel
LIMIT 100
