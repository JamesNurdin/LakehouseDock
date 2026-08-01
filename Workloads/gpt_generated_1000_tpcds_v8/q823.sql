WITH
  -- Base sales filtered on amount and quantity
  sales_base AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_addr_sk,
      ss.ss_promo_sk,
      ss.ss_net_paid,
      ss.ss_net_paid_inc_tax,
      ss.ss_ext_discount_amt,
      ss.ss_quantity,
      ss.ss_sold_date_sk,
      ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_quantity >= 2
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  ),

  -- Item filters
  item_filt AS (
    SELECT i.*
    FROM item i
    WHERE i.i_manager_id = 51
      AND i.i_container = 'Unknown'
  ),

  -- Promotion filters
  promo_filt AS (
    SELECT p.*
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_promo_name LIKE '%Discount%'
  ),

  -- Customer filters
  cust_filt AS (
    SELECT c.*
    FROM customer c
    WHERE c.c_birth_month IN (3, 5, 9)
      AND c.c_preferred_cust_flag = 'Y'
  ),

  -- Address filters
  addr_filt AS (
    SELECT ca.*
    FROM customer_address ca
    WHERE ca.ca_state = 'TX'
      AND ca.ca_gmt_offset = -6.00
  ),

  -- Left‑deep chain joining all five tables
  joined AS (
    SELECT
      sb.ss_item_sk,
      sb.ss_customer_sk,
      sb.ss_addr_sk,
      sb.ss_promo_sk,
      sb.ss_net_paid,
      sb.ss_net_paid_inc_tax,
      sb.ss_ext_discount_amt,
      sb.ss_quantity,
      sb.ss_sold_date_sk,
      sb.ss_ticket_number,
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city
    FROM sales_base sb
    JOIN item_filt i   ON sb.ss_item_sk = i.i_item_sk
    JOIN promo_filt p  ON sb.ss_promo_sk = p.p_promo_sk
    JOIN cust_filt c   ON sb.ss_customer_sk = c.c_customer_sk
    JOIN addr_filt ca  ON sb.ss_addr_sk = ca.ca_address_sk
  ),

  -- LATERAL subquery: total quantity bought by the same customer for the same item
  joined_lateral AS (
    SELECT
      j.*, 
      lt.total_qty_same_item
    FROM joined j
    LEFT JOIN LATERAL (
      SELECT SUM(ss2.ss_quantity) AS total_qty_same_item
      FROM store_sales ss2
      WHERE ss2.ss_customer_sk = j.ss_customer_sk
        AND ss2.ss_item_sk = j.ss_item_sk
    ) lt ON TRUE
  ),

  -- Anti‑join using NOT EXISTS (keep rows with no overlapping promotion on the same day)
  filtered_anti AS (
    SELECT *
    FROM joined_lateral jw
    WHERE NOT EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_name = jw.p_promo_name
        AND p2.p_start_date_sk < jw.ss_sold_date_sk
        AND p2.p_end_date_sk > jw.ss_sold_date_sk
        AND p2.p_promo_sk <> jw.ss_promo_sk
    )
  ),

  -- Aggregation per customer / city
  agg AS (
    SELECT
      c.c_customer_id,
      ca.ca_city,
      COUNT(DISTINCT fw.ss_ticket_number) AS orders_cnt,
      SUM(fw.ss_net_paid)               AS total_paid,
      AVG(fw.ss_ext_discount_amt)       AS avg_discount,
      MIN(fw.ss_net_paid_inc_tax)       AS min_paid_inc_tax,
      MAX(fw.ss_net_paid_inc_tax)       AS max_paid_inc_tax
    FROM filtered_anti fw
    JOIN customer c   ON fw.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON fw.ss_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_id, ca.ca_city
  ),

  -- Two key sets for set operations
  set_a AS (
    SELECT c_customer_id FROM agg WHERE total_paid > 5000
  ),
  set_b AS (
    SELECT c_customer_id FROM agg WHERE orders_cnt >= 5
  ),

  -- UNION of the two sets
  union_ab AS (
    SELECT c_customer_id FROM set_a
    UNION
    SELECT c_customer_id FROM set_b
  ),

  -- EXCEPT (A \ B)
  except_ab AS (
    SELECT c_customer_id FROM set_a
    EXCEPT
    SELECT c_customer_id FROM set_b
  ),

  -- INTERSECT (A ∩ B)
  intersect_ab AS (
    SELECT c_customer_id FROM set_a
    INTERSECT
    SELECT c_customer_id FROM set_b
  )

SELECT *
FROM (
  SELECT
    a.c_customer_id,
    a.total_paid,
    a.orders_cnt,
    'AGG'        AS src
  FROM agg a

  UNION ALL

  SELECT
    e.c_customer_id,
    NULL        AS total_paid,
    NULL        AS orders_cnt,
    'EXCEPT'    AS src
  FROM except_ab e

  UNION ALL

  SELECT
    i.c_customer_id,
    NULL        AS total_paid,
    NULL        AS orders_cnt,
    'INTERSECT' AS src
  FROM intersect_ab i
) q
ORDER BY src, total_paid DESC
OFFSET 0 LIMIT 100
