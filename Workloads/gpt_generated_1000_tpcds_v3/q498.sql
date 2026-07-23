SELECT
    s.s_store_id,
    d_cs_sold.d_year AS sale_year,
    i.i_category AS item_category,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) AS total_net_profit,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status
FROM
    catalog_sales cs
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    -- catalog returns
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    -- web sales
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    -- store
    JOIN store s ON s.s_closed_date_sk = d_cs_ship.d_date_sk
WHERE
    d_cs_sold.d_year = 2001
GROUP BY
    s.s_store_id,
    d_cs_sold.d_year,
    i.i_category
ORDER BY
    total_net_profit DESC
LIMIT 100
