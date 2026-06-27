WITH sales_agg AS (
    SELECT
        d_sale.d_year AS sales_year,
        p.p_promo_name,
        ca.ca_state,
        w.w_warehouse_name,
        sum(ws.ws_net_profit) AS total_net_profit,
        sum(ws.ws_ext_sales_price) AS total_sales_amount,
        count(*) AS total_sales_transactions,
        sum(ws.ws_ext_discount_amt) AS total_discount_amount,
        coalesce(sum(wr.wr_return_amt), 0) AS total_return_amount,
        sum(ws.ws_net_profit) - coalesce(sum(wr.wr_return_amt), 0) AS net_profit_after_returns
    FROM web_sales ws
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_date >= d_start.d_date
      AND d_sale.d_date <= d_end.d_date
      AND d_sale.d_year BETWEEN 2001 AND 2002
    GROUP BY d_sale.d_year, p.p_promo_name, ca.ca_state, w.w_warehouse_name
)
SELECT
    sales_year,
    p_promo_name,
    ca_state,
    w_warehouse_name,
    total_net_profit,
    total_sales_amount,
    total_sales_transactions,
    total_discount_amount,
    total_return_amount,
    net_profit_after_returns,
    rank() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY sales_year, profit_rank
LIMIT 50
