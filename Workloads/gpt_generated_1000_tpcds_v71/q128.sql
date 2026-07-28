WITH promo_stats AS (
    SELECT p.p_promo_sk,
           AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type AS ship_type,
    w.w_state,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    AVG(promo_stats.avg_discount) AS avg_promo_discount
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_cdemo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promo_stats ON promo_stats.p_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND cd.cd_gender = 'F'
  AND cd.cd_purchase_estimate >= 5000
  AND w.w_state = 'CA'
  AND sm.sm_ship_mode_sk = 3
GROUP BY d.d_year, d.d_month_seq, sm.sm_type, w.w_state
ORDER BY total_sales DESC
LIMIT 100
