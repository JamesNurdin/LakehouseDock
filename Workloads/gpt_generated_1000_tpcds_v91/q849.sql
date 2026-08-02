WITH sales_daily_agg AS (
   SELECT
      i.i_item_id AS item_id,
      i.i_brand AS brand,
      d_ss.d_year AS year,
      p.p_promo_name AS promo_name,
      ca_ss.ca_state AS state,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
      COUNT(DISTINCT ws.ws_order_number) AS web_txn_count
   FROM store_sales ss
   JOIN date_dim d_ss
     ON ss.ss_sold_date_sk = d_ss.d_date_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_address ca_ss
     ON ss.ss_addr_sk = ca_ss.ca_address_sk
   JOIN web_sales ws
     ON ws.ws_sold_date_sk = d_ss.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca_ws_bill
     ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
   WHERE d_ss.d_year = 1998
     AND i.i_brand = 'Brand#12'
     AND p.p_discount_active = 'Y'
     AND ca_ss.ca_state = 'CA'
     AND ss.ss_quantity > 2
     AND ws.ws_quantity > 1
     AND w.w_state = 'TX'
   GROUP BY GROUPING SETS (
     (i.i_item_id, i.i_brand, d_ss.d_year, p.p_promo_name, ca_ss.ca_state),
     (i.i_item_id, i.i_brand, d_ss.d_year, p.p_promo_name),
     (i.i_item_id, i.i_brand, d_ss.d_year),
     (i.i_item_id, i.i_brand),
     ()
   )
)
SELECT
   year,
   promo_name,
   state,
   SUM(store_sales_amount) AS total_store_sales,
   SUM(web_sales_amount) AS total_web_sales,
   AVG(total_net_profit) AS avg_net_profit,
   COUNT(*) AS grp_rows,
   (SELECT COUNT(DISTINCT w2.w_warehouse_id)
      FROM warehouse w2
      WHERE w2.w_state = sales_agg.state) AS warehouses_in_state
FROM sales_daily_agg sales_agg
WHERE store_sales_amount > 0
GROUP BY GROUPING SETS (
   (year, promo_name, state),
   (year, promo_name),
   (year),
   ()
)
HAVING AVG(total_net_profit) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
