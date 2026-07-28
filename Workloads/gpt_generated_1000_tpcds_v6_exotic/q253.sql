WITH
  -- 1. Aggregate inventory per item and warehouse (pre‑aggregation)
  agg_inventory AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),

  -- 2. Web sales (with all allowed joins) and a few filters
  web_sales_pre AS (
    SELECT
      ws.ws_item_sk               AS item_sk,
      ws.ws_warehouse_sk          AS warehouse_sk,
      ws.ws_sold_date_sk          AS date_sk,
      ws.ws_sold_time_sk          AS time_sk,
      ws.ws_quantity              AS quantity,
      ws.ws_ext_sales_price       AS amount,
      ws.ws_net_profit            AS profit,
      ws.ws_promo_sk              AS promo_sk,
      ws.ws_web_page_sk           AS web_page_sk,
      ws.ws_web_site_sk           AS web_site_sk,
      ws.ws_bill_customer_sk      AS customer_sk,
      ws.ws_bill_addr_sk          AS address_sk,
      NULL                        AS store_sk,
      NULL                        AS ticket_number,
      NULL                        AS reason_sk,
      NULL                        AS call_center_sk,
      NULL                        AS catalog_page_sk,
      'web'                       AS sales_channel
    FROM web_sales ws
    JOIN time_dim td          ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN customer c           ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca  ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE td.t_shift = 'first               '
      AND ws.ws_ext_sales_price > 1000
  ),

  -- 3. Store sales (allowed joins) and filters
  store_sales_pre AS (
    SELECT
      ss.ss_item_sk               AS item_sk,
      NULL                        AS warehouse_sk,
      ss.ss_sold_date_sk          AS date_sk,
      ss.ss_sold_time_sk          AS time_sk,
      ss.ss_quantity              AS quantity,
      ss.ss_ext_sales_price       AS amount,
      ss.ss_net_profit            AS profit,
      NULL                        AS promo_sk,
      NULL                        AS web_page_sk,
      NULL                        AS web_site_sk,
      ss.ss_customer_sk           AS customer_sk,
      ss.ss_addr_sk               AS address_sk,
      ss.ss_store_sk              AS store_sk,
      ss.ss_ticket_number         AS ticket_number,
      NULL                        AS reason_sk,
      NULL                        AS call_center_sk,
      NULL                        AS catalog_page_sk,
      'store'                     AS sales_channel
    FROM store_sales ss
    JOIN time_dim td          ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_shift = 'second               '
      AND ss.ss_ext_sales_price > 500
  ),

  -- 4. Catalog returns (allowed joins) with their own filters
  catalog_returns_pre AS (
    SELECT
      cr.cr_item_sk               AS item_sk,
      cr.cr_warehouse_sk          AS warehouse_sk,
      cr.cr_returned_date_sk      AS date_sk,
      cr.cr_returned_time_sk      AS time_sk,
      cr.cr_return_quantity       AS quantity,
      cr.cr_return_amount         AS amount,
      NULL                        AS profit,
      NULL                        AS promo_sk,
      NULL                        AS web_page_sk,
      NULL                        AS web_site_sk,
      cr.cr_refunded_customer_sk AS customer_sk,
      cr.cr_refunded_addr_sk      AS address_sk,
      NULL                        AS store_sk,
      cr.cr_order_number          AS ticket_number,
      cr.cr_reason_sk             AS reason_sk,
      cr.cr_call_center_sk        AS call_center_sk,
      cr.cr_catalog_page_sk       AS catalog_page_sk,
      'catalog_return'            AS sales_channel
    FROM catalog_returns cr
    JOIN time_dim td               ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i                    ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_ref           ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 200
      AND td.t_shift = 'third               '
  ),

  -- 5. Store returns (allowed joins) with filters
  store_returns_pre AS (
    SELECT
      sr.sr_item_sk               AS item_sk,
      NULL                        AS warehouse_sk,
      sr.sr_returned_date_sk      AS date_sk,
      sr.sr_return_time_sk        AS time_sk,
      sr.sr_return_quantity       AS quantity,
      sr.sr_return_amt            AS amount,
      NULL                        AS profit,
      NULL                        AS promo_sk,
      NULL                        AS web_page_sk,
      NULL                        AS web_site_sk,
      sr.sr_customer_sk           AS customer_sk,
      sr.sr_addr_sk               AS address_sk,
      sr.sr_store_sk              AS store_sk,
      sr.sr_ticket_number         AS ticket_number,
      sr.sr_reason_sk             AS reason_sk,
      NULL                        AS call_center_sk,
      NULL                        AS catalog_page_sk,
      'store_return'              AS sales_channel
    FROM store_returns sr
    JOIN time_dim td               ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i                    ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
      AND td.t_shift = 'first               '
  ),

  -- 6. Union all activity streams (set operation)
  unified_activity AS (
    SELECT * FROM web_sales_pre
    UNION ALL
    SELECT * FROM store_sales_pre
    UNION ALL
    SELECT * FROM catalog_returns_pre
    UNION ALL
    SELECT * FROM store_returns_pre
  ),

  -- 7. Join the unified stream to the remaining dimensions
  enriched AS (
    SELECT
      ua.item_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      ua.sales_channel,
      ua.amount,
      ua.profit,
      ua.quantity,
      ua.date_sk,
      ua.time_sk,
      ua.warehouse_sk,
      inv.total_qty,
      p.p_promo_name,
      wp.wp_url,
      site.web_name,
      cc.cc_name,
      cp.cp_description,
      r.r_reason_desc,
      ua.customer_sk,
      ua.address_sk,
      ua.store_sk,
      ua.ticket_number,
      -- scalar sub‑query: average inventory for the warehouse of this row (may be null)
      (SELECT AVG(total_qty) FROM agg_inventory ai WHERE ai.inv_warehouse_sk = ua.warehouse_sk) AS avg_warehouse_qty
    FROM unified_activity ua
    JOIN item i               ON ua.item_sk = i.i_item_sk
    LEFT JOIN agg_inventory inv ON i.i_item_sk = inv.inv_item_sk AND ua.warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN promotion p      ON ua.promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp      ON ua.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site site    ON ua.web_site_sk = site.web_site_sk
    LEFT JOIN call_center cc   ON ua.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp  ON ua.catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r         ON ua.reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w      ON ua.warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category = 'Electronics'
      AND ua.amount > 2000
      AND (w.w_city = 'Seattle' OR w.w_city IS NULL)
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND (cp.cp_type = 'TypeA' OR cp.cp_type IS NULL)
      AND (r.r_reason_desc LIKE '%damage%' OR r.r_reason_desc IS NULL)
      AND EXISTS (
        SELECT 1
        FROM store_returns_pre sr
        WHERE sr.item_sk = ua.item_sk AND sr.amount > 1000
      )
  )
SELECT
  e.i_item_id,
  e.i_product_name,
  e.i_category,
  e.sales_channel,
  e.amount,
  e.profit,
  e.quantity,
  e.total_qty,
  e.p_promo_name,
  e.wp_url,
  e.web_name,
  e.cc_name,
  e.cp_description,
  e.r_reason_desc,
  RANK() OVER (PARTITION BY e.sales_channel ORDER BY e.amount DESC) AS sales_rank,
  CASE
    WHEN e.total_qty IS NULL THEN 'No Inventory'
    WHEN e.total_qty < 100 THEN 'Low Stock'
    ELSE 'Sufficient Stock'
  END AS inventory_status,
  e.avg_warehouse_qty
FROM enriched e
ORDER BY sales_rank
LIMIT 100
