WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS sales_transactions,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_promos
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY w.web_site_id, w.web_name
)
SELECT
    web_site_id,
    web_name,
    promo_count,
    total_net_profit,
    total_net_paid_inc_tax,
    avg_purchase_estimate,
    sales_transactions,
    active_discount_promos,
    CASE
        WHEN active_discount_promos >= 5 THEN 'Aggressive Promotion'
        WHEN active_discount_promos BETWEEN 1 AND 4 THEN 'Moderate Promotion'
        ELSE 'No Active Promotion'
    END AS promotion_intensity,
    ROW_NUMBER() OVER (ORDER BY total_net_paid_inc_tax DESC) AS paid_tax_rank
FROM site_metrics
WHERE sales_transactions > 0
ORDER BY paid_tax_rank
LIMIT 20
