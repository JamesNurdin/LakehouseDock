WITH base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        s.s_state,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        cs.cs_order_number,
        cs.cs_ext_ship_cost,
        cs.cs_quantity,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ca.ca_address_sk,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_call_center_sk,
        cp.cp_catalog_page_sk,
        wp.wp_web_page_sk
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_net_loss > 100.00
      AND cs.cs_ext_ship_cost BETWEEN 500.00 AND 2000.00
      AND ws.ws_net_profit > 50.00
      AND cr.cr_return_quantity = 4
      AND ib.ib_lower_bound >= 50000
      AND s.s_state = 'CA'
)
SELECT
    s_state,
    s_store_name,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(cs_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
    MIN(sr_return_quantity) AS min_return_qty,
    MAX(ws_quantity) AS max_web_qty,
    RANK() OVER (PARTITION BY s_state ORDER BY SUM(sr_net_loss) DESC) AS state_store_rank
FROM base
GROUP BY s_state, s_store_name
ORDER BY total_net_loss DESC
LIMIT 100
