WITH base AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cc.cc_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand_id IN (2004001, 3002001)
      AND ws.ws_coupon_amt > 100
      AND cr.cr_return_amount > 20
      AND inv.inv_quantity_on_hand < 200
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state, cc.cc_name
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    b.w_warehouse_id,
    b.w_city,
    b.cc_name,
    b.total_net_profit,
    b.total_return_amount,
    b.total_net_profit - b.total_return_amount AS net_gain,
    RANK() OVER (ORDER BY b.total_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY b.w_state ORDER BY b.total_net_profit DESC) AS state_rank
FROM base b
ORDER BY profit_rank
LIMIT 100
