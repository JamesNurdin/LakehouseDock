WITH catalog_orders AS (
   SELECT cs.cs_order_number AS order_number,
          w.w_warehouse_sk,
          p.p_promo_sk,
          cp.cp_department
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND w.w_state = 'CA'
     AND i.i_brand = 'Brand#12'
     AND p.p_discount_active = 'Y'
     AND hd.hd_buy_potential = '1001-5000'
     AND cp.cp_department = 'Electronics'
),
web_orders AS (
   SELECT ws.ws_order_number AS order_number,
          w.w_warehouse_sk,
          p.p_promo_sk,
          s.web_state,
          wr.wr_return_quantity
   FROM web_sales ws
   JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
   WHERE d2.d_year = 2001
     AND s.web_state = 'CA'
     AND i.i_brand = 'Brand#12'
     AND p.p_discount_active = 'Y'
     AND hd_bill.hd_buy_potential = '1001-5000'
     AND wr.wr_return_quantity > 0
)
SELECT
   w.w_warehouse_name,
   p.p_promo_name,
   COUNT(t.order_number) AS orders_count,
   SUM((SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = t.order_number)) AS total_catalog_sales
FROM (
   SELECT order_number, w_warehouse_sk, p_promo_sk FROM catalog_orders
   EXCEPT
   SELECT order_number, w_warehouse_sk, p_promo_sk FROM web_orders
) AS t
JOIN warehouse w ON t.w_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON t.p_promo_sk = p.p_promo_sk
GROUP BY w.w_warehouse_name, p.p_promo_name
ORDER BY total_catalog_sales DESC
LIMIT 100
