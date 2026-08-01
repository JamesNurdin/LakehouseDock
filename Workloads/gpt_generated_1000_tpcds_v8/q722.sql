WITH
  sales_full AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      ss.ss_quantity            AS quantity,
      ss.ss_net_paid           AS net_paid,
      ss.ss_net_profit         AS net_profit,
      s.s_store_name           AS store_name,
      s.s_state                AS store_state,
      ca.ca_state              AS address_state,
      CAST(NULL AS varchar)    AS warehouse_name,
      CAST(NULL AS varchar)    AS ship_mode,
      CAST(NULL AS varchar)    AS reason_desc,
      CAST(NULL AS varchar)    AS call_center_name
    FROM store_sales ss
    FULL OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_category IN ('Electronics', 'Furniture')
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
    UNION
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      ws.ws_quantity           AS quantity,
      ws.ws_net_paid           AS net_paid,
      ws.ws_net_profit         AS net_profit,
      CAST(NULL AS varchar)    AS store_name,
      CAST(NULL AS varchar)    AS store_state,
      ca.ca_state              AS address_state,
      w.w_warehouse_name       AS warehouse_name,
      sm.sm_type               AS ship_mode,
      CAST(NULL AS varchar)    AS reason_desc,
      CAST(NULL AS varchar)    AS call_center_name
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_category IN ('Electronics', 'Furniture')
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
  ),
  returns_full AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      cr.cr_return_quantity      AS quantity,
      cr.cr_return_amount        AS net_paid,
      cr.cr_net_loss            AS net_profit,
      CAST(NULL AS varchar)     AS store_name,
      CAST(NULL AS varchar)     AS store_state,
      ca.ca_state               AS address_state,
      w.w_warehouse_name        AS warehouse_name,
      sm.sm_type                AS ship_mode,
      r.r_reason_desc           AS reason_desc,
      cc.cc_name                AS call_center_name
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_category IN ('Electronics', 'Furniture')
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
  ),
  unioned AS (
    SELECT * FROM sales_full
    UNION
    SELECT * FROM returns_full
  )
SELECT
  i_category,
  d_year,
  MAX(i_brand)          AS i_brand,
  MAX(p_promo_name)    AS promo_name,
  SUM(quantity)        AS total_quantity,
  SUM(net_paid)        AS total_net_paid,
  SUM(net_profit)      AS total_net_profit,
  COUNT(DISTINCT store_name)     AS distinct_store_cnt,
  COUNT(DISTINCT warehouse_name) AS distinct_warehouse_cnt,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(quantity) DESC) AS rank_by_quantity
FROM unioned
WHERE i_brand IN (SELECT i_brand FROM item WHERE i_manager_id = 3)
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_name = unioned.p_promo_name
          AND p2.p_cost > 1000
      )
GROUP BY ROLLUP (i_category, d_year)
HAVING SUM(quantity) > 0
   AND SUM(net_paid) > (
        SELECT MIN(d_year) FROM date_dim WHERE d_year >= 1999
      )
ORDER BY d_year DESC, i_category
LIMIT 100
