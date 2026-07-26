WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) FILTER (WHERE p.p_discount_active = 'Y') AS active_discount_promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_paid_inc_tax > 0
    GROUP BY w.web_site_id, w.web_name
)
SELECT
    web_site_id,
    web_name,
    active_discount_promo_count,
    total_net_profit,
    total_net_paid_inc_tax,
    avg_purchase_estimate,
    total_tax,
    total_quantity,
    CASE
        WHEN total_quantity / NULLIF(active_discount_promo_count,0) > 100 THEN 'High Volume'
        ELSE 'Normal Volume'
    END AS volume_category,
    ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_net_profit DESC) AS profit_rank
FROM site_metrics
ORDER BY total_net_profit DESC
