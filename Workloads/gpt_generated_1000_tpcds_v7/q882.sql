WITH billed AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        'bill_demo' AS demo_side
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
      AND cd.cd_purchase_estimate > 5000
      AND p.p_channel_catalog = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name
),
shipped AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        'ship_demo' AS demo_side
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count >= 3
      AND p.p_channel_email = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT * FROM billed
UNION ALL
SELECT * FROM shipped
LIMIT 100
