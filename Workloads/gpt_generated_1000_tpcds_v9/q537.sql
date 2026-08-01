WITH cat_agg AS (
    SELECT
        cc.cc_call_center_id,
        td.t_hour,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(r.cr_net_loss, 0)) AS catalog_return_loss,
        SUM(cs.cs_net_profit) - SUM(COALESCE(r.cr_net_loss, 0)) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns r
        ON r.cr_order_number = cs.cs_order_number
        AND r.cr_item_sk = cs.cs_item_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND cd.cd_purchase_estimate >= 8000
        AND cc.cc_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_return_amount > 100
        )
    GROUP BY cc.cc_call_center_id, td.t_hour
),
ws_agg AS (
    SELECT
        td.t_hour,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND cd.cd_education_status = 'Advanced Degree'
        AND wp.wp_url LIKE 'http://www.%'
    GROUP BY td.t_hour
)
SELECT
    ca.cc_call_center_id,
    ca.t_hour,
    ca.catalog_profit,
    ca.catalog_return_loss,
    ca.catalog_net_profit,
    COALESCE(wa.web_profit, 0) AS web_profit,
    ca.catalog_net_profit + COALESCE(wa.web_profit, 0) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY ca.t_hour ORDER BY ca.catalog_net_profit + COALESCE(wa.web_profit, 0) DESC) AS profit_rank,
    CASE
        WHEN ca.catalog_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS catalog_status,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_return_amount > 0) AS avg_return_amount
FROM cat_agg ca
LEFT JOIN ws_agg wa
    ON ca.t_hour = wa.t_hour
ORDER BY total_profit DESC
LIMIT 100
