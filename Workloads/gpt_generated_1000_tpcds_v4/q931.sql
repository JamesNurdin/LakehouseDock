SELECT
       d.d_year,
       i.i_brand,
       COUNT(DISTINCT cs.cs_order_number)                     AS order_cnt,
       SUM(cs.cs_ext_sales_price)                              AS total_sales,
       SUM(CASE WHEN i.i_color = 'Red' THEN cs.cs_ext_sales_price ELSE 0 END) AS red_sales,
       AVG(p.p_cost)                                            AS avg_promo_cost,
       MAX(inv.inv_quantity_on_hand)                           AS max_inventory,
       SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END)    AS male_cust_cnt,
       COUNT(*) FILTER (WHERE wr.wr_return_quantity > 0)      AS web_return_cnt
FROM catalog_sales cs
JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

-- store side
JOIN store_sales ss           ON ss.ss_item_sk = i.i_item_sk
                                 AND ss.ss_sold_date_sk = d.d_date_sk
JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr        ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_store_sk = s.s_store_sk

-- inventory side
JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv           ON inv.inv_date_sk = d_inv.d_date_sk

-- web side
JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr            ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp            ON wp.wp_creation_date_sk = d_wp.d_date_sk
JOIN web_site ws              ON ws.web_open_date_sk = d_wp.d_date_sk

WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND cd.cd_gender = 'M'
  AND p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_cost > 1000
      )
GROUP BY d.d_year, i.i_brand
ORDER BY total_sales DESC
LIMIT 100
