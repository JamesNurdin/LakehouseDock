WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        AVG(ws.ws_sales_price) AS avg_sale_price
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sales_price > 20
      AND wsite.web_class = 'Unknown'
      AND sm.sm_contract LIKE 'A%'
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer_demographics cd
          WHERE cd.cd_demo_sk = ws.ws_bill_cdemo_sk
            AND cd.cd_gender = 'M'
      )
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk
)
SELECT
    wsite.web_site_id,
    sm.sm_ship_mode_id,
    agg.total_profit,
    agg.distinct_customers,
    agg.avg_sale_price,
    (SELECT COUNT(*) FROM tpcds.ship_mode sm2 WHERE sm2.sm_contract LIKE 'A%') AS total_a_contracts
FROM sales_agg agg
JOIN tpcds.web_site wsite
    ON agg.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.ship_mode sm
    ON agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws_neg
    WHERE ws_neg.ws_web_site_sk = agg.ws_web_site_sk
      AND ws_neg.ws_net_profit < 0
)
ORDER BY agg.total_profit DESC
LIMIT 100
