WITH catalog_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND cd.cd_credit_rating = 'Low Risk'
      AND sm.sm_type = 'AIR'
      AND cs.cs_sold_date_sk >= 2450000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
web_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wsit.web_country = 'United States'
      AND wp.wp_type = 'Content'
      AND p.p_discount_active = 'Y'
      AND cd.cd_credit_rating = 'Low Risk'
      AND sm.sm_type = 'AIR'
      AND ws.ws_sold_date_sk >= 2450000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
combined AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        catalog_net_paid,
        catalog_net_profit,
        catalog_orders,
        catalog_net_loss,
        0 AS web_net_paid,
        0 AS web_net_profit,
        0 AS web_orders,
        0 AS web_net_loss,
        'catalog' AS source
    FROM catalog_data
    UNION ALL
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        0,
        0,
        0,
        0,
        web_net_paid,
        web_net_profit,
        web_orders,
        web_net_loss,
        'web' AS source
    FROM web_data
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(combined.catalog_net_paid) AS total_catalog_paid,
    SUM(combined.catalog_net_profit) AS total_catalog_profit,
    SUM(combined.web_net_paid) AS total_web_paid,
    SUM(combined.web_net_profit) AS total_web_profit,
    SUM(combined.catalog_net_loss) AS total_catalog_loss,
    SUM(combined.web_net_loss) AS total_web_loss,
    CASE
        WHEN SUM(combined.catalog_net_profit) + SUM(combined.web_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(combined.catalog_net_profit) + SUM(combined.web_net_profit) BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY (SUM(combined.catalog_net_profit) + SUM(combined.web_net_profit)) DESC) AS profit_rank,
    (SELECT AVG(cs.cs_net_paid) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS avg_catalog_paid,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS web_return_count
FROM combined
JOIN customer c ON combined.c_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_customer_sk
HAVING (SUM(combined.catalog_net_profit) + SUM(combined.web_net_profit)) > 2000
ORDER BY profit_rank
LIMIT 100
