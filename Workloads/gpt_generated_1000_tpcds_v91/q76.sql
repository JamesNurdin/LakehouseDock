WITH inv_agg AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    inv.total_on_hand,
    SUM(cs.cs_quantity) AS catalog_qty,
    SUM(cs.cs_net_paid) AS catalog_sales,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(ws.ws_quantity) AS web_qty,
    SUM(ws.ws_net_paid) AS web_sales,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(srt.sr_return_quantity) AS store_return_qty,
    SUM(srt.sr_net_loss) AS store_return_loss,
    SUM(promo_item.p_cost) AS promo_total_cost,
    MAX(cc_cs.cc_name) AS call_center_name,
    MAX(web.web_name) AS web_site_name
FROM item i
JOIN inv_agg inv ON inv.inv_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer cust_cs_bill ON cs.cs_bill_customer_sk = cust_cs_bill.c_customer_sk
JOIN customer cust_cs_ship ON cs.cs_ship_customer_sk = cust_cs_ship.c_customer_sk
JOIN call_center cc_cs ON cs.cs_call_center_sk = cc_cs.cc_call_center_sk
JOIN catalog_page cp_cs ON cs.cs_catalog_page_sk = cp_cs.cp_catalog_page_sk
JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN customer cust_cr_refund ON cr.cr_refunded_customer_sk = cust_cr_refund.c_customer_sk
JOIN customer cust_cr_return ON cr.cr_returning_customer_sk = cust_cr_return.c_customer_sk
JOIN promotion promo_item ON promo_item.p_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer cust_ws_bill ON ws.ws_bill_customer_sk = cust_ws_bill.c_customer_sk
JOIN customer cust_ws_ship ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
JOIN promotion promo_ws ON ws.ws_promo_sk = promo_ws.p_promo_sk
JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer cust_wr_refund ON wr.wr_refunded_customer_sk = cust_wr_refund.c_customer_sk
JOIN customer cust_wr_return ON wr.wr_returning_customer_sk = cust_wr_return.c_customer_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN store_returns srt ON srt.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr ON srt.sr_return_time_sk = t_sr.t_time_sk
JOIN customer cust_srt ON srt.sr_customer_sk = cust_srt.c_customer_sk
WHERE i.i_rec_start_date >= DATE '2000-01-01'
  AND i.i_rec_start_date < DATE '2001-01-01'
GROUP BY i.i_item_id, i.i_item_desc, i.i_brand, i.i_category, inv.total_on_hand
UNION
SELECT
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    inv.total_on_hand,
    SUM(cs.cs_quantity) AS catalog_qty,
    SUM(cs.cs_net_paid) AS catalog_sales,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(ws.ws_quantity) AS web_qty,
    SUM(ws.ws_net_paid) AS web_sales,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(srt.sr_return_quantity) AS store_return_qty,
    SUM(srt.sr_net_loss) AS store_return_loss,
    SUM(promo_item.p_cost) AS promo_total_cost,
    MAX(cc_cs.cc_name) AS call_center_name,
    MAX(web.web_name) AS web_site_name
FROM item i
JOIN inv_agg inv ON inv.inv_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer cust_cs_bill ON cs.cs_bill_customer_sk = cust_cs_bill.c_customer_sk
JOIN customer cust_cs_ship ON cs.cs_ship_customer_sk = cust_cs_ship.c_customer_sk
JOIN call_center cc_cs ON cs.cs_call_center_sk = cc_cs.cc_call_center_sk
JOIN catalog_page cp_cs ON cs.cs_catalog_page_sk = cp_cs.cp_catalog_page_sk
JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN customer cust_cr_refund ON cr.cr_refunded_customer_sk = cust_cr_refund.c_customer_sk
JOIN customer cust_cr_return ON cr.cr_returning_customer_sk = cust_cr_return.c_customer_sk
JOIN promotion promo_item ON promo_item.p_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer cust_ws_bill ON ws.ws_bill_customer_sk = cust_ws_bill.c_customer_sk
JOIN customer cust_ws_ship ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
JOIN promotion promo_ws ON ws.ws_promo_sk = promo_ws.p_promo_sk
JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer cust_wr_refund ON wr.wr_refunded_customer_sk = cust_wr_refund.c_customer_sk
JOIN customer cust_wr_return ON wr.wr_returning_customer_sk = cust_wr_return.c_customer_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN store_returns srt ON srt.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr ON srt.sr_return_time_sk = t_sr.t_time_sk
JOIN customer cust_srt ON srt.sr_customer_sk = cust_srt.c_customer_sk
WHERE i.i_rec_start_date >= DATE '2001-01-01'
  AND i.i_rec_start_date < DATE '2002-01-01'
GROUP BY i.i_item_id, i.i_item_desc, i.i_brand, i.i_category, inv.total_on_hand
LIMIT 100
