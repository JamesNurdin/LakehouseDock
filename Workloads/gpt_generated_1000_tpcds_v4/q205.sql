WITH ws_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_country,
        p.p_promo_id,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 3000
      AND w.w_country = 'United States'
      AND p.p_discount_active = 'Y'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_country, p.p_promo_id
),
cr_agg AS (
    SELECT
        w.w_warehouse_sk,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_store_credit) AS total_store_credit,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_refunded_cash > 500
      AND cr.cr_return_amount > 50
    GROUP BY w.w_warehouse_sk
)
SELECT
    ws.w_warehouse_id,
    ws.w_country,
    ws.p_promo_id,
    ws.total_sales,
    ws.total_profit,
    cr.total_refunded_cash,
    cr.total_store_credit,
    (ws.total_sales - cr.total_refunded_cash) AS net_sales_after_refund,
    CASE WHEN ws.total_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (ORDER BY (ws.total_sales - cr.total_refunded_cash) DESC) AS sales_rank
FROM ws_agg ws
LEFT JOIN cr_agg cr ON ws.w_warehouse_sk = cr.w_warehouse_sk
ORDER BY sales_rank
LIMIT 100
