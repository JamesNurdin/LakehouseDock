WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_quantity,
        ss_net_paid,
        ss_net_profit
    FROM store_sales
),
ws AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sold_time_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_cdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_addr_sk,
        ws_web_page_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
),
wr AS (
    SELECT
        wr_item_sk,
        wr_order_number,
        wr_returned_time_sk,
        wr_reason_sk,
        wr_return_amt,
        wr_net_loss,
        wr_refunded_cdemo_sk,
        wr_refunded_hdemo_sk,
        wr_refunded_addr_sk,
        wr_returning_cdemo_sk,
        wr_returning_hdemo_sk,
        wr_returning_addr_sk,
        wr_web_page_sk
    FROM web_returns
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    r.r_reason_desc,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_contribution
FROM ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN ws ON ss.ss_item_sk = ws.ws_item_sk
    AND ss.ss_promo_sk = ws.ws_promo_sk
    AND ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
LEFT JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
LEFT JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
LEFT JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
LEFT JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
LEFT JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
LEFT JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN wr ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
LEFT JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
LEFT JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE s.s_rec_start_date >= DATE '2000-01-01'
  AND p.p_channel_tv = 'N'
GROUP BY s.s_store_name, p.p_promo_name, r.r_reason_desc
ORDER BY net_contribution DESC
LIMIT 100
