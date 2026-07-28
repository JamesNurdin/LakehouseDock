WITH sales_returns AS (
    SELECT
        s.s_division_name AS division_name,
        p.p_promo_name AS promo_name,
        d_sold.d_year AS year,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                         AND ws.ws_item_sk = wr.wr_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND s.s_market_id IN (5, 6, 7)
    GROUP BY s.s_division_name, p.p_promo_name, d_sold.d_year
)
SELECT
    division_name,
    promo_name,
    year,
    total_sales,
    total_discount,
    total_returns,
    net_profit,
    total_sales / NULLIF(total_discount, 0) AS sales_per_discount
FROM sales_returns
WHERE net_profit > 0
ORDER BY net_profit DESC
LIMIT 100
