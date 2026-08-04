WITH ss_agg AS (
       SELECT ss_store_sk,
              ss_sold_date_sk,
              SUM(ss_net_paid)   AS total_net_paid,
              SUM(ss_quantity)   AS total_qty
       FROM   store_sales
       GROUP BY ss_store_sk, ss_sold_date_sk
     )
SELECT dimension_store_name,
       dimension_web_url,
       promotion_name,
       income_range,
       SUM(total_net_paid)   AS agg_net_paid,
       SUM(total_qty)        AS agg_qty,
       SUM(inv_total_qty)    AS agg_inv_qty
FROM (
      -- Store side branch
      SELECT s.s_store_name                               AS dimension_store_name,
             CAST(NULL AS varchar)                        AS dimension_web_url,
             p.p_promo_name                               AS promotion_name,
             CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar))
                                                         AS income_range,
             SUM(ss.total_net_paid)                       AS total_net_paid,
             SUM(ss.total_qty)                            AS total_qty,
             SUM(inv_lateral.inv_total_qty)               AS inv_total_qty
      FROM   ss_agg ss
      JOIN   store s
        ON   ss.ss_store_sk = s.s_store_sk
      JOIN   date_dim d
        ON   ss.ss_sold_date_sk = d.d_date_sk
      LEFT JOIN store_returns sr
        ON   s.s_store_sk = sr.sr_store_sk
       AND   sr.sr_returned_date_sk = d.d_date_sk
      FULL OUTER JOIN catalog_returns cr
        ON   sr.sr_returned_date_sk = cr.cr_returned_date_sk
      JOIN   catalog_page cp
        ON   cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN   ship_mode sm
        ON   cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN   customer c_ref
        ON   cr.cr_refunded_customer_sk = c_ref.c_customer_sk
      JOIN   customer_address ca_ref
        ON   cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
      JOIN   customer_demographics cd_ref
        ON   cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
      JOIN   household_demographics hd_ref
        ON   cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
      JOIN   income_band ib
        ON   hd_ref.hd_income_band_sk = ib.ib_income_band_sk
      LEFT JOIN promotion p
        ON   p.p_start_date_sk = d.d_date_sk
      CROSS JOIN LATERAL (
          SELECT SUM(i.inv_quantity_on_hand) AS inv_total_qty
          FROM   inventory i
          WHERE  i.inv_date_sk = d.d_date_sk
      ) AS inv_lateral
      WHERE EXISTS (
          SELECT 1
          FROM   promotion p2
          WHERE  p2.p_promo_sk = p.p_promo_sk
          AND    p2.p_discount_active = 'Y'
      )
      GROUP BY s.s_store_name,
               p.p_promo_name,
               ib.ib_lower_bound,
               ib.ib_upper_bound,
               inv_lateral.inv_total_qty

      UNION

      -- Web side branch
      SELECT CAST(NULL AS varchar)                         AS dimension_store_name,
             wp.wp_url                                    AS dimension_web_url,
             p.p_promo_name                               AS promotion_name,
             CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar))
                                                         AS income_range,
             SUM(ws.ws_net_paid)                         AS total_net_paid,
             SUM(ws.ws_quantity)                         AS total_qty,
             SUM(inv_lateral.inv_total_qty)               AS inv_total_qty
      FROM   web_sales ws
      JOIN   date_dim d
        ON   ws.ws_sold_date_sk = d.d_date_sk
      JOIN   web_page wp
        ON   ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN   promotion p
        ON   ws.ws_promo_sk = p.p_promo_sk
      JOIN   customer c
        ON   ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN   customer_address ca
        ON   ws.ws_bill_addr_sk = ca.ca_address_sk
      JOIN   customer_demographics cd
        ON   ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      JOIN   household_demographics hd
        ON   ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      JOIN   income_band ib
        ON   hd.hd_income_band_sk = ib.ib_income_band_sk
      CROSS JOIN LATERAL (
          SELECT SUM(i.inv_quantity_on_hand) AS inv_total_qty
          FROM   inventory i
          WHERE  i.inv_date_sk = d.d_date_sk
      ) AS inv_lateral
      WHERE EXISTS (
          SELECT 1
          FROM   promotion p2
          WHERE  p2.p_promo_sk = ws.ws_promo_sk
          AND    p2.p_discount_active = 'Y'
      )
      GROUP BY wp.wp_url,
               p.p_promo_name,
               ib.ib_lower_bound,
               ib.ib_upper_bound,
               inv_lateral.inv_total_qty
) t
GROUP BY CUBE (dimension_store_name, dimension_web_url, promotion_name, income_range)
LIMIT 100
