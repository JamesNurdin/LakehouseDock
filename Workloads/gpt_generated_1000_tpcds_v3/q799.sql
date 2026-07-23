WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_day_name,
        d_sold.d_date,
        c.c_birth_year,
        p.p_channel_demo,
        p.p_channel_event,
        w.w_warehouse_name,
        wp.wp_url,
        wp.wp_type,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_reason_sk
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
           AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND d_sold.d_date >= DATE '2001-01-01'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND p.p_channel_demo = 'N'
      AND p.p_channel_event = 'N'
      AND d_sold.d_day_name = 'Monday'
      AND ws.ws_quantity > 2
      AND ws.ws_net_profit > 0
      AND wp.wp_type = 'product'
)
SELECT
    sr.ws_order_number,
    sr.w_warehouse_name,
    sr.d_year,
    sr.d_month_seq,
    sr.c_birth_year,
    sr.ws_quantity,
    sr.ws_net_profit,
    COALESCE(sr.wr_return_amt, 0) AS return_amount,
    (sr.ws_net_profit - COALESCE(sr.wr_return_amt, 0)) AS profit_after_returns,
    CASE
        WHEN (sr.ws_net_profit - COALESCE(sr.wr_return_amt, 0)) >= 100 THEN 'High'
        WHEN (sr.ws_net_profit - COALESCE(sr.wr_return_amt, 0)) >= 50 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier,
    RANK() OVER (PARTITION BY sr.w_warehouse_name ORDER BY sr.ws_net_profit DESC) AS profit_rank_warehouse,
    ROW_NUMBER() OVER (ORDER BY (sr.ws_net_profit - COALESCE(sr.wr_return_amt, 0)) DESC) AS overall_row_num
FROM sales_returns sr
WHERE EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_sk = sr.wr_reason_sk
      AND r.r_reason_desc = 'Customer returned'
)
ORDER BY profit_after_returns DESC, sr.ws_order_number
LIMIT 100
