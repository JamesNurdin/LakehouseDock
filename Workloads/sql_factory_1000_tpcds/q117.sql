WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS sales_transactions
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
    CASE
        WHEN sales_transactions >= 1000 THEN 'High Volume'
        WHEN sales_transactions BETWEEN 500 AND 999 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS purchase_estimate_rank
FROM site_metrics
WHERE promo_count > 0
ORDER BY purchase_estimate_rank
