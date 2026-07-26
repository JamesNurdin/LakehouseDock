WITH site_metrics AS (
    SELECT
        w.web_site_id,
        w.web_name,
        COUNT(DISTINCT ws.ws_promo_sk) AS promo_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(cd_bill.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_ext_tax) AS total_tax,
        MAX(ws.ws_net_paid) AS max_single_payment,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ship_mode_sk IS NOT NULL AND ws.ws_ext_ship_cost > 0
    GROUP BY w.web_site_id, w.web_name
    HAVING SUM(ws.ws_net_profit) BETWEEN 0 AND 10000
)
SELECT
    web_site_id,
    web_name,
    promo_count,
    total_net_profit,
    total_net_paid_inc_tax,
    avg_purchase_estimate,
    total_tax,
    max_single_payment,
    total_shipping_cost,
    CASE
        WHEN total_shipping_cost > 5000 THEN 'Expensive Shipping'
        ELSE 'Standard Shipping'
    END AS shipping_category,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM site_metrics
ORDER BY profit_rank ASC
