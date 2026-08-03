WITH inv_sum AS (
   SELECT inv_item_sk,
          SUM(inv_quantity_on_hand) AS total_qty,
          MAX(inv_quantity_on_hand) AS max_qty
   FROM inventory
   WHERE inv_warehouse_sk IN (15, 14)
   GROUP BY inv_item_sk
)
SELECT
   d.d_year,
   d.d_month_seq,
   cc.cc_name,
   p.p_promo_name,
   ws.web_name,
   COUNT(DISTINCT ss.ss_ticket_number)               AS store_sales_cnt,
   SUM(ss.ss_net_paid)                               AS total_store_net_paid,
   SUM(cs.cs_net_paid)                               AS total_catalog_net_paid,
   SUM(wr.wr_return_amt)                             AS total_web_return_amount,
   SUM(cr.cr_return_amount)                          AS total_catalog_return_amount,
   AVG(ss.ss_quantity)                               AS avg_store_quantity,
   SUM(inv_sum.total_qty)                            AS total_inventory_qty,
   MAX(inv_sum.max_qty)                              AS max_inventory_qty,
   (SELECT AVG(cs2.cs_ext_discount_amt)
      FROM catalog_sales cs2)                       AS avg_catalog_discount
FROM store_sales ss
RIGHT OUTER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_item_sk IN (SELECT inv_item_sk
                               FROM inventory
                               WHERE inv_quantity_on_hand > 100)
JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inv_sum
        ON cs.cs_item_sk = inv_sum.inv_item_sk
WHERE d.d_year = 2002
  AND cc.cc_state = 'CA'
  AND c.c_salutation = 'Mrs.'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count >= 2
  AND cs.cs_quantity > 1
GROUP BY d.d_year,
         d.d_month_seq,
         cc.cc_name,
         p.p_promo_name,
         ws.web_name,
         inv_sum.total_qty,
         inv_sum.max_qty
ORDER BY total_store_net_paid DESC
LIMIT 100
