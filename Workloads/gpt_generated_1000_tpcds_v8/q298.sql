WITH catalog_keys AS (
       SELECT cs_order_number
       FROM catalog_sales
   ),
   web_return_keys AS (
       SELECT wr_order_number
       FROM web_returns
   ),
   cat_not_return AS (
       SELECT cs_order_number
       FROM catalog_keys
       EXCEPT
       SELECT wr_order_number
       FROM web_return_keys
   ),
   cs AS (
       SELECT cs.cs_order_number,
              cs.cs_sold_date_sk,
              cs.cs_item_sk,
              cs.cs_bill_customer_sk,
              cs.cs_promo_sk,
              cs.cs_net_paid,
              cs.cs_ext_sales_price
       FROM catalog_sales cs
       JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
       JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
       JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
       WHERE cp.cp_department = 'Books'
   ),
   ss AS (
       SELECT ss.ss_ticket_number,
              ss.ss_sold_date_sk,
              ss.ss_item_sk,
              ss.ss_customer_sk,
              ss.ss_promo_sk,
              ss.ss_net_paid
       FROM store_sales ss
       JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
       JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
   ),
   ws AS (
       SELECT ws.ws_order_number,
              ws.ws_sold_date_sk,
              ws.ws_item_sk,
              ws.ws_bill_customer_sk,
              ws.ws_promo_sk,
              ws.ws_net_paid
       FROM web_sales ws
       JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
       JOIN promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk
       JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   ),
   inv AS (
       SELECT inv.inv_item_sk,
              inv.inv_date_sk,
              inv.inv_quantity_on_hand
       FROM inventory inv
       JOIN item i4 ON inv.inv_item_sk = i4.i_item_sk
   ),
   wr AS (
       SELECT wr.wr_order_number,
              wr.wr_returned_date_sk,
              wr.wr_item_sk,
              wr.wr_refunded_customer_sk,
              wr.wr_return_amt,
              wr.wr_net_loss
       FROM web_returns wr
       JOIN web_sales ws4 ON wr.wr_order_number = ws4.ws_order_number
       JOIN item i5 ON wr.wr_item_sk = i5.i_item_sk
   ),
   final AS (
       SELECT COALESCE(cs.cs_order_number, ss.ss_ticket_number) AS order_id,
              CASE WHEN cs.cs_order_number IS NOT NULL THEN 'Catalog' ELSE 'Store' END AS source_type,
              SUM( COALESCE(cs.cs_net_paid, 0) +
                   COALESCE(ss.ss_net_paid, 0) +
                   COALESCE(ws.ws_net_paid, 0) -
                   COALESCE(wr.wr_net_loss, 0) ) AS total_revenue,
              COUNT(DISTINCT COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk)) AS distinct_items_sold,
              SUM( CASE WHEN p1.p_discount_active = 'Y' THEN cs.cs_ext_sales_price * 0.9
                        ELSE cs.cs_ext_sales_price END ) AS adjusted_sales
       FROM cat_not_return cnr
       LEFT JOIN cs ON cnr.cs_order_number = cs.cs_order_number
       FULL OUTER JOIN ss ON cs.cs_order_number = ss.ss_ticket_number
       LEFT JOIN ws ON COALESCE(cs.cs_order_number, ss.ss_ticket_number) = ws.ws_order_number
       LEFT JOIN wr ON ws.ws_order_number = wr.wr_order_number
       LEFT JOIN item i_main ON COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk) = i_main.i_item_sk
       LEFT JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
       LEFT JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
       LEFT JOIN promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk
       LEFT JOIN customer c_main ON COALESCE(cs.cs_bill_customer_sk, ss.ss_customer_sk, ws.ws_bill_customer_sk) = c_main.c_customer_sk
       LEFT JOIN customer_demographics cd_main ON c_main.c_current_cdemo_sk = cd_main.cd_demo_sk
       LEFT JOIN household_demographics hd_main ON c_main.c_current_hdemo_sk = hd_main.hd_demo_sk
       LEFT JOIN inventory inv ON i_main.i_item_sk = inv.inv_item_sk
       WHERE i_main.i_category = 'Sports'
       GROUP BY COALESCE(cs.cs_order_number, ss.ss_ticket_number),
                CASE WHEN cs.cs_order_number IS NOT NULL THEN 'Catalog' ELSE 'Store' END
       HAVING SUM( COALESCE(cs.cs_net_paid, 0) +
                    COALESCE(ss.ss_net_paid, 0) +
                    COALESCE(ws.ws_net_paid, 0) -
                    COALESCE(wr.wr_net_loss, 0) ) > 1000
   )
SELECT order_id,
       source_type,
       total_revenue,
       distinct_items_sold,
       adjusted_sales
FROM final
LIMIT 100
