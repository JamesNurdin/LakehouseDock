WITH filtered_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_refunded_cdemo_sk,
        cr.cr_warehouse_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        i.inv_quantity_on_hand,
        i.inv_warehouse_sk,
        p.p_cost,
        w.w_warehouse_name,
        w.w_city,
        w.w_warehouse_sq_ft,
        we.web_state,
        we.web_zip,
        we.web_rec_start_date,
        we.web_rec_end_date,
        cd_refunded.cd_gender
    FROM catalog_returns cr
    INNER JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE we.web_state = 'CA'
      AND we.web_zip = '33604'
      AND we.web_rec_start_date >= DATE '2000-01-01'
      AND we.web_rec_end_date <= DATE '2025-12-31'
      AND p.p_cost > 5000.00
      AND cr.cr_return_amount > 100.00
      AND ws.ws_quantity >= 2
      AND i.inv_quantity_on_hand < 500
      AND cd_refunded.cd_gender = 'M'
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    we.web_state,
    CASE WHEN w.w_warehouse_sq_ft > 100000 THEN 'Large' ELSE 'Small' END AS warehouse_size,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_net_profit_overall
FROM filtered_data fd
INNER JOIN catalog_returns cr ON cr.cr_return_amount = fd.cr_return_amount
INNER JOIN web_sales ws ON ws.ws_order_number = fd.ws_order_number
INNER JOIN warehouse w ON w.w_warehouse_name = fd.w_warehouse_name
INNER JOIN web_site we ON we.web_state = fd.web_state
INNER JOIN promotion p ON p.p_cost = fd.p_cost
INNER JOIN inventory i ON i.inv_quantity_on_hand = fd.inv_quantity_on_hand
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    we.web_state,
    w.w_warehouse_sq_ft
ORDER BY total_net_profit DESC
LIMIT 100
