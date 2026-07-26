WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS sales_transactions,
        MIN(ws.ws_sold_date_sk) AS first_sale_date_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_profit > 0
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
        WHEN sales_transactions >= 1500 THEN 'Very High Volume'
        WHEN sales_transactions >= 800 THEN 'High Volume'
        WHEN sales_transactions >= 400 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    first_sale_date_sk
FROM site_metrics
WHERE promo_count >= 2
ORDER BY profit_rank
LIMIT 50
