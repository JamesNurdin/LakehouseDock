SELECT
    i.i_category,
    d_sold.d_month_seq,
    p.p_promo_name,
    wp.wp_type,
    ca_bill.ca_state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    AVG(i.i_current_price) AS avg_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
FROM tpcds.store_returns sr
JOIN tpcds.date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN tpcds.item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca_ret
  ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN tpcds.date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN tpcds.date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN tpcds.date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_current_price BETWEEN 20 AND 100
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'ad'
  AND ca_bill.ca_state = 'CA'
  AND inv.inv_quantity_on_hand > 50
  AND d_ret.d_month_seq = 5
GROUP BY i.i_category,
         d_sold.d_month_seq,
         p.p_promo_name,
         wp.wp_type,
         ca_bill.ca_state
HAVING SUM(ws.ws_net_paid) > 10000
   AND COUNT(DISTINCT ws.ws_order_number) > 10
LIMIT 100
