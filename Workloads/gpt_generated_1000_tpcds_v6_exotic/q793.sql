WITH sales_with_promo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_discount_active,
        s.s_store_id,
        s.s_state,
        s.s_city
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND ws.ws_quantity > 1
)
SELECT
    swp.d_year,
    swp.d_month_seq,
    swp.p_promo_name,
    swp.s_state,
    COUNT(DISTINCT swp.ws_order_number) AS orders_cnt,
    SUM(swp.ws_quantity) AS total_quantity,
    SUM(swp.ws_ext_sales_price) AS total_sales,
    AVG(swp.ws_ext_discount_amt) AS avg_discount,
    SUM(swp.ws_net_profit) AS total_profit,
    SUM(COALESCE((
        SELECT SUM(r.wr_return_amt)
        FROM web_returns r
        WHERE r.wr_order_number = swp.ws_order_number
          AND r.wr_item_sk = swp.ws_item_sk), 0)) AS total_return_amount,
    SUM(COALESCE((
        SELECT SUM(r.wr_net_loss)
        FROM web_returns r
        WHERE r.wr_order_number = swp.ws_order_number
          AND r.wr_item_sk = swp.ws_item_sk), 0)) AS total_net_loss
FROM sales_with_promo swp
WHERE EXISTS (
    SELECT 1
    FROM web_returns r
    WHERE r.wr_order_number = swp.ws_order_number
      AND r.wr_item_sk = swp.ws_item_sk
      AND r.wr_return_quantity > 0
)
GROUP BY
    swp.d_year,
    swp.d_month_seq,
    swp.p_promo_name,
    swp.s_state
ORDER BY
    total_sales DESC,
    orders_cnt DESC
LIMIT 100
