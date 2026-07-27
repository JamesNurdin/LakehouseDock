WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 20
      AND wr_fee > 10
      AND wr_refunded_cash > 30
      AND wr_return_ship_cost > 15
    GROUP BY wr_order_number
    HAVING SUM(wr_return_amt) > 50
)
SELECT
    p.p_promo_name,
    w.w_warehouse_name,
    wp.wp_type,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(r.total_return_qty, 0)) AS total_return_qty,
    SUM(COALESCE(r.total_return_amt, 0)) AS total_return_amt,
    CASE
        WHEN SUM(COALESCE(r.total_return_qty, 0)) > SUM(ws.ws_quantity) THEN 'High Return'
        ELSE 'Normal'
    END AS return_category,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_dense_rank
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN returns_agg r ON ws.ws_order_number = r.wr_order_number
WHERE ws.ws_quantity >= 10
  AND ws.ws_ext_sales_price > 500
  AND ws.ws_net_paid_inc_ship > 1000
  AND wp.wp_access_date_sk IN (2452596, 2452623, 2452620, 2452580, 2452646)
  AND p.p_discount_active = 'Y'
GROUP BY p.p_promo_name, w.w_warehouse_name, wp.wp_type
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
