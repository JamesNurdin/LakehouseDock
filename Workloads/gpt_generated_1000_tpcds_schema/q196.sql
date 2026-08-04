WITH
  -- scalar subquery returning a single value
  max_cs_price AS (
    SELECT max(cs_ext_sales_price) AS max_price
    FROM tpcds.catalog_sales
  ),

  -- a tiny dimension used for a CROSS JOIN later
  flag_dim AS (
    SELECT 'Y' AS flag
  ),

  -- small filtered gender list for later join
  gender_dim AS (
    SELECT cd_gender
    FROM tpcds.customer_demographics
    WHERE cd_gender IN ('M', 'F')
  ),

  -- catalog‑sales side of the UNION
  catalog_part AS (
    SELECT
      d.d_date               AS sale_date,
      c.c_customer_id,
      cs.cs_ext_sales_price  AS sales_amount,
      'catalog'              AS source,
      cd.cd_gender,
      w.w_warehouse_name    AS warehouse_name,
      i.i_product_name      AS product_name,
      p.p_promo_name        AS promo_name,
      r.r_reason_desc       AS reason_desc,
      s.s_store_name        AS store_name,
      cc.cc_name             AS call_center_name,
      inv.inv_quantity_on_hand AS inventory_qty,
      wp.wp_url               AS web_page_url
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs   ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN tpcds.customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.item i              ON cs.cs_item_sk       = i.i_item_sk
    JOIN tpcds.warehouse w         ON cs.cs_warehouse_sk  = w.w_warehouse_sk
    JOIN tpcds.promotion p         ON cs.cs_promo_sk      = p.p_promo_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.reason r          ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.store s           ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc    ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory inv     ON inv.inv_date_sk = d.d_date_sk
                                    AND inv.inv_item_sk = i.i_item_sk
                                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.web_page wp       ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cs.cs_coupon_amt > 1000
      AND w.w_county = 'Wadena County'
      AND cd.cd_gender = 'M'
      AND cs.cs_ext_sales_price > (SELECT max_price FROM max_cs_price)
  ),

  -- web‑sales side of the UNION
  web_part AS (
    SELECT
      d.d_date               AS sale_date,
      c.c_customer_id,
      ws.ws_ext_sales_price AS sales_amount,
      'web'                 AS source,
      cd.cd_gender,
      w.w_warehouse_name    AS warehouse_name,
      i.i_product_name      AS product_name,
      p.p_promo_name        AS promo_name,
      r.r_reason_desc       AS reason_desc,
      s.s_store_name        AS store_name,
      cc.cc_name            AS call_center_name,
      inv.inv_quantity_on_hand AS inventory_qty,
      wp.wp_url               AS web_page_url
    FROM tpcds.date_dim d
    JOIN tpcds.web_sales ws      ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN tpcds.customer c         ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.item i             ON ws.ws_item_sk        = i.i_item_sk
    JOIN tpcds.warehouse w        ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN tpcds.promotion p        ON ws.ws_promo_sk       = p.p_promo_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.reason r         ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.store s          ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc   ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory inv    ON inv.inv_date_sk = d.d_date_sk
                                    AND inv.inv_item_sk = i.i_item_sk
                                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.web_page wp      ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ws.ws_coupon_amt > 500
      AND w.w_county = 'Wadena County'
      AND cd.cd_gender = 'F'
      AND ws.ws_ext_sales_price > (SELECT max_price FROM max_cs_price)
  ),

  -- union of both sides, distinct rows only
  unified AS (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
  )

SELECT
  u.sale_date,
  u.c_customer_id,
  u.sales_amount,
  u.source,
  u.cd_gender,
  u.warehouse_name,
  u.product_name,
  u.promo_name,
  u.reason_desc,
  u.store_name,
  u.call_center_name,
  u.inventory_qty,
  u.web_page_url,
  ROW_NUMBER() OVER (PARTITION BY u.source ORDER BY u.sales_amount DESC) AS sales_rank,
  f.flag
FROM unified u
CROSS JOIN flag_dim f
JOIN gender_dim g ON g.cd_gender = u.cd_gender
ORDER BY sales_rank, u.source
LIMIT 100
