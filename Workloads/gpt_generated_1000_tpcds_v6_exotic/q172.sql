WITH
    inventory_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand,
            w.w_warehouse_name,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            p1.p_promo_name        AS p1_promo_name,
            p_item.p_promo_name    AS p_item_promo_name,
            p2.p_promo_name        AS p2_promo_name,
            SUM(cs.cs_net_paid)    AS total_catalog_net_paid,
            SUM(ss.ss_net_paid)    AS total_store_net_paid,
            SUM(sr.sr_return_amt)  AS total_store_returns,
            SUM(wr.wr_return_amt)  AS total_web_returns,
            inventory_agg.total_qty_on_hand,
            (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) - SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS net_revenue
        FROM catalog_sales cs
        JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
        JOIN promotion p_item ON p_item.p_item_sk = i.i_item_sk
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
        JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
        JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
        JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
        JOIN customer c_return ON sr.sr_customer_sk = c_return.c_customer_sk
        JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = i.i_item_sk
        JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
        JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
        JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
        JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
        JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
        JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
        JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
        JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
        JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
        JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
        JOIN customer c_wr_return ON wr.wr_returning_customer_sk = c_wr_return.c_customer_sk
        JOIN customer_address ca_wr_return ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
        LEFT JOIN inventory_agg ON inventory_agg.inv_item_sk = i.i_item_sk
                                 AND inventory_agg.inv_warehouse_sk = w.w_warehouse_sk
        GROUP BY
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand,
            w.w_warehouse_name,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            p1.p_promo_name,
            p_item.p_promo_name,
            p2.p_promo_name,
            inventory_agg.total_qty_on_hand
    )
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.i_category,
    sa.i_brand,
    sa.w_warehouse_name,
    sa.cc_name,
    sa.cp_department,
    sa.sm_type,
    sa.p1_promo_name,
    sa.p_item_promo_name,
    sa.p2_promo_name,
    sa.total_catalog_net_paid,
    sa.total_store_net_paid,
    sa.total_store_returns,
    sa.total_web_returns,
    sa.total_qty_on_hand,
    sa.net_revenue,
    ROW_NUMBER() OVER (PARTITION BY sa.i_category ORDER BY sa.net_revenue DESC) AS category_rank
FROM sales_agg sa
ORDER BY sa.net_revenue DESC
LIMIT 100
