WITH joined AS (
  SELECT
    d.d_year,
    w_c.w_warehouse_name               AS catalog_warehouse,
    i_c.i_category                     AS catalog_category,
    i_c.i_item_sk                      AS item_sk,
    cs.cs_net_profit                   AS catalog_profit,
    ss.ss_net_profit                   AS store_profit,
    ws.ws_net_profit                   AS web_profit,
    cr.cr_net_loss                     AS catalog_return_loss,
    sr.sr_net_loss                     AS store_return_loss,
    wr.wr_net_loss                     AS web_return_loss,
    p.p_discount_active,
    sm_c.sm_code                        AS catalog_ship_mode,
    r_s.r_reason_desc                  AS store_return_reason,
    r_cr.r_reason_desc                 AS catalog_return_reason,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    inv.inv_quantity_on_hand,
    wp.wp_max_ad_count,
    wsit.web_zip
  FROM date_dim d
  -- catalog side
  JOIN catalog_sales cs          ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm_c            ON cs.cs_ship_mode_sk = sm_c.sm_ship_mode_sk
  JOIN warehouse w_c             ON cs.cs_warehouse_sk = w_c.w_warehouse_sk
  JOIN item i_c                  ON cs.cs_item_sk = i_c.i_item_sk
  JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
  -- catalog returns (linked to catalog sales)
  JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
  JOIN ship_mode sm_cr           ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  JOIN reason r_cr               ON cr.cr_reason_sk = r_cr.r_reason_sk
  JOIN warehouse w_cr            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  -- store side
  JOIN store_sales ss            ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i_s                  ON ss.ss_item_sk = i_s.i_item_sk
  JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
  JOIN reason r_s                ON sr.sr_reason_sk = r_s.r_reason_sk
  -- web side
  JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i_w                  ON ws.ws_item_sk = i_w.i_item_sk
  JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit             ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN ship_mode sm_w            ON ws.ws_ship_mode_sk = sm_w.sm_ship_mode_sk
  JOIN web_returns wr            ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
  JOIN reason r_w                ON wr.wr_reason_sk = r_w.r_reason_sk
  -- inventory (tied to catalog item/warehouse/date)
  JOIN inventory inv             ON inv.inv_item_sk = i_c.i_item_sk
                                 AND inv.inv_warehouse_sk = w_c.w_warehouse_sk
                                 AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
)
SELECT
  d_year,
  catalog_warehouse,
  SUM(catalog_profit)           AS total_catalog_profit,
  SUM(store_profit)             AS total_store_profit,
  SUM(web_profit)               AS total_web_profit,
  AVG(inv_quantity_on_hand)     AS avg_inventory_on_sale,
  COUNT(DISTINCT catalog_category) AS distinct_catalog_categories
FROM joined
WHERE catalog_ship_mode IN ('SEA','AIR')
  AND wp_max_ad_count > 1
  AND web_zip = '93511'
  AND p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = joined.item_sk
          AND inv2.inv_quantity_on_hand > 0
      )
GROUP BY d_year, catalog_warehouse
HAVING SUM(catalog_profit) > 0
ORDER BY total_catalog_profit DESC
LIMIT 100
