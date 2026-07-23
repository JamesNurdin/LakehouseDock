WITH ws_base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        c.c_customer_id,
        c.c_birth_year,
        hd.hd_income_band_sk,
        ca.ca_address_sk,
        wp.wp_url,
        ws_site.web_site_id,
        sm.sm_type,
        w.w_warehouse_name,
        td.t_hour,
        td.t_time_sk AS time_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1970
        AND i.i_current_price > 20.00
        AND ws.ws_quantity >= 2
        AND ws.ws_ext_tax > 10.00
        AND td.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1 FROM income_band ib
            WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
              AND ib.ib_lower_bound >= 50000
        )
)
SELECT
    s.s_store_name,
    s.s_market_id,
    ws_base.c_customer_id,
    ws_base.c_birth_year,
    ws_base.i_item_id,
    ws_base.i_product_name,
    ws_base.i_current_price,
    CASE WHEN ws_base.i_current_price > 100 THEN 'High' ELSE 'Standard' END AS price_category,
    ws_base.ws_quantity,
    ws_base.ws_net_paid,
    ws_base.ws_net_profit,
    sr.sr_return_quantity,
    sr.sr_net_loss AS store_return_net_loss,
    wr.wr_return_quantity,
    wr.wr_net_loss AS web_return_net_loss,
    r.r_reason_desc AS store_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    ws_base.wp_url AS web_page_url,
    wp_wr.wp_url AS web_return_page_url,
    ws_base.sm_type AS ship_mode_type,
    ws_base.w_warehouse_name,
    ws_base.t_hour,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY ws_base.ws_net_profit DESC) AS store_sales_rank,
    SUM(ws_base.ws_net_profit) OVER (PARTITION BY s.s_store_sk) AS total_store_net_profit,
    CASE
        WHEN SUM(ws_base.ws_net_profit) OVER (PARTITION BY s.s_store_sk) > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS store_profitability
FROM ws_base
JOIN store_returns sr ON sr.sr_item_sk = ws_base.ws_item_sk AND sr.sr_return_time_sk = ws_base.time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = ws_base.ws_item_sk AND wr.wr_order_number = ws_base.ws_order_number AND wr.wr_returned_time_sk = ws_base.time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
WHERE s.s_market_id IN (1, 4, 6)
ORDER BY store_sales_rank, s.s_store_name
LIMIT 100
