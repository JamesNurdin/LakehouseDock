SELECT
    s.s_division_name,
    d_sold.d_year,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer cust_bill
  ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d2
  ON ss.ss_sold_date_sk = d2.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d3
  ON s.s_closed_date_sk = d3.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d4
  ON ws.ws_sold_date_sk = d4.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d5
  ON wp.wp_creation_date_sk = d5.d_date_sk
JOIN customer_address ca_ws
  ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
GROUP BY
    s.s_division_name,
    d_sold.d_year,
    p.p_promo_name
ORDER BY total_net_profit DESC,
         s.s_division_name
LIMIT 100
