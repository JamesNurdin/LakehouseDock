WITH sales_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        p.p_discount_active,
        w.w_state
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    w_state,
    CASE WHEN p_discount_active = 'Y' THEN 'Promotion' ELSE 'No Promotion' END AS promo_status,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_discount_amt) AS total_discount,
    SUM(ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_order_number) AS order_count,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_details
WHERE d_year = 2001
GROUP BY
    d_year,
    d_month_seq,
    i_category,
    w_state,
    CASE WHEN p_discount_active = 'Y' THEN 'Promotion' ELSE 'No Promotion' END
ORDER BY
    d_year,
    d_month_seq,
    profit_rank
