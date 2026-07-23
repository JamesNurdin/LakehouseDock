/*
  Goal: Aggregate sales, returns and net profit by item across catalog, web and store channels, include promotion count and classify profit level.
*/
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_class,
    COALESCE(SUM(cs.cs_ext_sales_price), 0)                AS total_catalog_sales,
    COALESCE(SUM(ws.ws_ext_sales_price), 0)                AS total_web_sales,
    COALESCE(SUM(cr.cr_return_amount), 0)                  AS total_catalog_returns,
    COALESCE(SUM(wr.wr_return_amt), 0)                    AS total_web_returns,
    COALESCE(SUM(sr.sr_return_amt), 0)                    AS total_store_returns,
    COALESCE(SUM(cs.cs_net_profit), 0)
    + COALESCE(SUM(ws.ws_net_profit), 0)
    - COALESCE(SUM(cr.cr_net_loss), 0)
    - COALESCE(SUM(wr.wr_net_loss), 0)
    - COALESCE(SUM(sr.sr_net_loss), 0)                       AS net_profit,
    CASE
        WHEN COALESCE(SUM(cs.cs_net_profit), 0)
           + COALESCE(SUM(ws.ws_net_profit), 0)
           - COALESCE(SUM(cr.cr_net_loss), 0)
           - COALESCE(SUM(wr.wr_net_loss), 0)
           - COALESCE(SUM(sr.sr_net_loss), 0) > 10000 THEN 'High Profit'
        ELSE 'Low Profit'
    END                                                     AS profit_category,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS promotion_count
FROM
    item i
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk

    /* Catalog Returns */
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN call_center cc_cr
        ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
    LEFT JOIN catalog_page cp_cr
        ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN customer cust_refunded
        ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
    LEFT JOIN customer cust_returning
        ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
    LEFT JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk

    /* Web Sales */
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN customer cust_ws_bill
        ON ws.ws_bill_customer_sk = cust_ws_bill.c_customer_sk
    LEFT JOIN customer cust_ws_ship
        ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
    LEFT JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    LEFT JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk

    /* Web Returns */
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN customer cust_wr_refunded
        ON wr.wr_refunded_customer_sk = cust_wr_refunded.c_customer_sk
    LEFT JOIN customer cust_wr_returning
        ON wr.wr_returning_customer_sk = cust_wr_returning.c_customer_sk
    LEFT JOIN household_demographics hd_wr_refunded
        ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

    /* Store Returns */
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer cust_sr
        ON sr.sr_customer_sk = cust_sr.c_customer_sk
    LEFT JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
WHERE
    i.i_item_id IS NOT NULL
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_class,
    i.i_item_sk
ORDER BY
    net_profit DESC,
    i.i_item_id
LIMIT 100
