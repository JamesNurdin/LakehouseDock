WITH agg_all AS (
   SELECT
      store_id,
      state,
      SUM(return_amount)               AS total_return_amount,
      AVG(net_loss)                    AS avg_net_loss,
      COUNT(DISTINCT order_number)     AS distinct_orders,
      SUM(ext_sales_price)             AS total_store_sales,
      SUM(ws_ext_sales_price)          AS total_web_sales,
      ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY SUM(ext_sales_price) DESC) AS rn
   FROM (
      SELECT
         s.s_store_id                     AS store_id,
         s.s_state                        AS state,
         cr.cr_return_amount              AS return_amount,
         cr.cr_net_loss                   AS net_loss,
         cr.cr_order_number               AS order_number,
         ss.ss_ext_sales_price            AS ext_sales_price,
         ws.ws_ext_sales_price            AS ws_ext_sales_price
      FROM catalog_returns cr
      JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
      JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
      JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
      WHERE c.c_preferred_cust_flag = 'Y'
        AND c.c_first_sales_date_sk = 2451187
        AND wp.wp_image_count > 3
        AND cr.cr_return_tax > 5.00
        AND s.s_state = 'CA'
   ) sub
   GROUP BY GROUPING SETS (
      (store_id, state),
      (store_id),
      (state),
      ()
   )
   HAVING SUM(ext_sales_price) > 500
),
agg_exclude AS (
   SELECT
      store_id,
      state,
      SUM(return_amount)               AS total_return_amount,
      AVG(net_loss)                    AS avg_net_loss,
      COUNT(DISTINCT order_number)     AS distinct_orders,
      SUM(ext_sales_price)             AS total_store_sales,
      SUM(ws_ext_sales_price)          AS total_web_sales,
      ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY SUM(ext_sales_price) DESC) AS rn
   FROM (
      SELECT
         s.s_store_id                     AS store_id,
         s.s_state                        AS state,
         cr.cr_return_amount              AS return_amount,
         cr.cr_net_loss                   AS net_loss,
         cr.cr_order_number               AS order_number,
         ss.ss_ext_sales_price            AS ext_sales_price,
         ws.ws_ext_sales_price            AS ws_ext_sales_price
      FROM catalog_returns cr
      JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
      JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
      JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
      WHERE c.c_preferred_cust_flag = 'Y'
        AND c.c_first_sales_date_sk = 2451187
        AND wp.wp_image_count > 5
        AND cr.cr_return_tax > 5.00
        AND s.s_state = 'CA'
   ) sub2
   GROUP BY GROUPING SETS (
      (store_id, state),
      (store_id),
      (state),
      ()
   )
   HAVING SUM(ext_sales_price) > 500
)
SELECT *
FROM agg_all
EXCEPT
SELECT *
FROM agg_exclude
LIMIT 100
