WITH unioned AS (
    SELECT
        s.s_store_name AS store_name,
        w.w_warehouse_name AS warehouse_name,
        hd.hd_buy_potential AS buy_potential,
        ca.ca_state AS state,
        cr.cr_return_amount AS catalog_return_amount,
        cr.cr_fee AS catalog_fee,
        cr.cr_net_loss AS catalog_net_loss,
        cr.cr_return_quantity AS catalog_return_qty,
        sr.sr_return_amt AS store_return_amount,
        sr.sr_fee AS store_fee,
        sr.sr_net_loss AS store_net_loss,
        sr.sr_return_quantity AS store_return_qty,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_ext_discount_amt AS web_discount,
        wr.wr_return_amt AS web_return_amount,
        wr.wr_fee AS web_fee,
        wr.wr_net_loss AS web_net_loss,
        wr.wr_return_quantity AS web_return_qty,
        inv.inv_quantity_on_hand AS quantity_on_hand
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
    JOIN catalog_returns cr ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ca.ca_state = 'CA'
        AND hd.hd_buy_potential = '0-500'
        AND w.w_state = 'TX'

    UNION

    SELECT
        s.s_store_name AS store_name,
        w.w_warehouse_name AS warehouse_name,
        hd.hd_buy_potential AS buy_potential,
        ca.ca_state AS state,
        cr.cr_return_amount AS catalog_return_amount,
        cr.cr_fee AS catalog_fee,
        cr.cr_net_loss AS catalog_net_loss,
        cr.cr_return_quantity AS catalog_return_qty,
        sr.sr_return_amt AS store_return_amount,
        sr.sr_fee AS store_fee,
        sr.sr_net_loss AS store_net_loss,
        sr.sr_return_quantity AS store_return_qty,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_ext_discount_amt AS web_discount,
        wr.wr_return_amt AS web_return_amount,
        wr.wr_fee AS web_fee,
        wr.wr_net_loss AS web_net_loss,
        wr.wr_return_quantity AS web_return_qty,
        inv.inv_quantity_on_hand AS quantity_on_hand
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
    JOIN catalog_returns cr ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_addr_sk = ca.ca_address_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_returning_addr_sk = ca.ca_address_sk
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ca.ca_state = 'NY'
        AND hd.hd_income_band_sk = 9
        AND w.w_gmt_offset = -5.00
)
SELECT
    store_name,
    warehouse_name,
    buy_potential,
    state,
    COUNT(*) AS transaction_count,
    SUM(catalog_return_amount) AS total_catalog_return_amount,
    SUM(store_return_amount) AS total_store_return_amount,
    SUM(web_return_amount) AS total_web_return_amount,
    SUM(catalog_fee) + SUM(store_fee) + SUM(web_fee) AS total_fees,
    SUM(catalog_net_loss) + SUM(store_net_loss) + SUM(web_net_loss) AS total_net_loss,
    SUM(catalog_return_qty) + SUM(store_return_qty) + SUM(web_return_qty) AS total_return_quantity,
    AVG(web_sales_price) AS avg_web_sales_price,
    MIN(quantity_on_hand) AS min_quantity_on_hand,
    MAX(quantity_on_hand) AS max_quantity_on_hand
FROM unioned
GROUP BY store_name, warehouse_name, buy_potential, state
ORDER BY total_net_loss DESC
LIMIT 100
