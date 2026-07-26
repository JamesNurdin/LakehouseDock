WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY w.web_site_id, w.web_name
    HAVING COUNT(*) >= 10
)
SELECT
    web_site_id,
    web_name,
    promo_count,
    total_net_profit,
    total_net_paid_inc_tax,
    avg_purchase_estimate,
    total_tax,
    sales_transactions,
    CASE
        WHEN avg_purchase_estimate > 5000 THEN 'High Estimate'
        ELSE 'Standard Estimate'
    END AS estimate_category,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM site_metrics
ORDER BY profit_rank ASC
