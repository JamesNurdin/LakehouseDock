WITH base AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.i_category,
        d_sold.d_year
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse wh_ws
        ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN customer_address ca_wr_refund
        ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    LEFT JOIN customer_address ca_wr_return
        ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = wh.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
)
SELECT
    i_category,
    d_year,
    SUM(cs_ext_sales_price) AS catalog_sales,
    SUM(ws_ext_sales_price) AS web_sales,
    SUM(sr_return_amt) AS store_return_amount,
    SUM(wr_return_amt) AS web_return_amount,
    SUM(cs_net_profit) + SUM(ws_net_profit) - COALESCE(SUM(sr_net_loss), 0) - COALESCE(SUM(wr_net_loss), 0) AS net_gain
FROM base
GROUP BY i_category, d_year
ORDER BY net_gain DESC
LIMIT 100
