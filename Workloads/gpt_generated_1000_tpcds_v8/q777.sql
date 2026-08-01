WITH
  -- 1. Sample a fraction of catalog_sales for performance
  catalog_sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2451000 AND 2451100
  ),

  -- 2. Enrich sampled catalog sales with all allowed dimensions
  catalog_sales_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      sm.sm_type,
      cp.cp_type,
      c.c_customer_id,
      ca.ca_state
    FROM catalog_sales_sample cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type = 'quarterly'
      AND p.p_promo_name = 'Holiday'
      AND i.i_brand = 'Brand#12'
      AND cs.cs_quantity > 2
      AND cs.cs_net_paid > 100.00
  ),

  -- 3. Store sales enriched (ship mode not available, use NULL placeholder)
  store_sales_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      NULL AS sm_type,
      s.s_store_name,
      c.c_customer_id,
      ca.ca_state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_net_paid > 50.00
      AND s.s_state = 'CA'
      AND p.p_promo_name = 'Clearance'
      AND i.i_category = 'Sports'
  ),

  -- 4. Web sales enriched
  web_sales_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      sm.sm_type,
      c.c_customer_id,
      ca.ca_state
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_quantity >= 3
      AND ws.ws_net_paid_inc_tax > 120.00
      AND i.i_brand = 'Brand#23'
      AND sm.sm_type = 'AIR'
      AND ca.ca_country = 'United States'
  ),

  -- 5. Returns (to be used for EXCEPT later)
  returns_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.i_category,
      ca.ca_state
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10.00
  ),

  -- 6. Orders that appear in returns
  returns_orders AS (
    SELECT DISTINCT cr_order_number AS order_id FROM catalog_returns
  ),

  -- 7. Orders that appear in any sales channel
  sales_orders AS (
    SELECT DISTINCT cs_order_number AS order_id FROM catalog_sales_join
    UNION
    SELECT DISTINCT ss_ticket_number FROM store_sales_join
    UNION
    SELECT DISTINCT ws_order_number FROM web_sales_join
  ),

  -- 8. Orders that have sales but no returns (EXCEPT demonstration)
  sales_not_returned AS (
    SELECT order_id FROM sales_orders
    EXCEPT
    SELECT order_id FROM returns_orders
  ),

  -- 9. Small dimension (promo channels) – built from promotion table
  promo_channel AS (
    SELECT DISTINCT p_channel_dmail AS channel FROM promotion
    UNION
    SELECT DISTINCT p_channel_email FROM promotion
  ),

  -- 10. Distinct product categories – small set
  category_set AS (
    SELECT DISTINCT i_category FROM item
  ),

  -- 11. CROSS JOIN between the two tiny sets (demonstrates cartesian product)
  cross_join_set AS (
    SELECT pc.channel, cs.i_category
    FROM promo_channel pc
    CROSS JOIN category_set cs
    LIMIT 10
  ),

  -- 12. Union of the three sales sources (UNION DISTINCT used)
  union_sales AS (
    SELECT
      cs_order_number AS order_id,
      cs_sold_date_sk AS date_sk,
      cs_quantity AS quantity,
      cs_ext_sales_price AS sales_amount,
      cs_net_profit AS profit,
      i_category,
      i_brand,
      p_promo_name,
      sm_type,
      c_customer_id,
      ca_state
    FROM catalog_sales_join
    UNION DISTINCT
    SELECT
      ss_ticket_number,
      ss_sold_date_sk,
      ss_quantity,
      ss_ext_sales_price,
      ss_net_profit,
      i_category,
      i_brand,
      p_promo_name,
      sm_type,
      c_customer_id,
      ca_state
    FROM store_sales_join
    UNION DISTINCT
    SELECT
      ws_order_number,
      ws_sold_date_sk,
      ws_quantity,
      ws_ext_sales_price,
      ws_net_profit,
      i_category,
      i_brand,
      p_promo_name,
      sm_type,
      c_customer_id,
      ca_state
    FROM web_sales_join
  ),

  -- 13. Filter unioned sales to keep only orders without returns (using the EXCEPT‑derived set)
  filtered_union_sales AS (
    SELECT us.*
    FROM union_sales us
    JOIN sales_not_returned snr ON us.order_id = snr.order_id
  ),

  -- 14. Aggregate with GROUPING SETS (multi‑level roll‑up)
  final_agg AS (
    SELECT
      date_sk,
      i_category,
      i_brand,
      p_promo_name,
      SUM(sales_amount) AS total_sales,
      AVG(profit) AS avg_profit,
      COUNT(DISTINCT order_id) AS distinct_orders,
      MIN(sales_amount) AS min_sale,
      MAX(sales_amount) AS max_sale,
      -- scalar subquery: total number of return rows for the same category (could be zero)
      (SELECT COUNT(*) FROM returns_join r WHERE r.i_category = filtered_union_sales.i_category) AS returns_in_category
    FROM filtered_union_sales
    GROUP BY GROUPING SETS (
      (date_sk, i_category, i_brand, p_promo_name),
      (date_sk, i_category, i_brand),
      (date_sk, i_category),
      (date_sk)
    )
  )
SELECT
  date_sk,
  i_category,
  i_brand,
  p_promo_name,
  total_sales,
  avg_profit,
  distinct_orders,
  min_sale,
  max_sale,
  returns_in_category
FROM final_agg
ORDER BY total_sales DESC
LIMIT 100
