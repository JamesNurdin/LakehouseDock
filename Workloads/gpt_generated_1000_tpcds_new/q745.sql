WITH
  base AS (
    SELECT
      cp.cp_catalog_page_id,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_profit,
      cs.cs_item_sk,
      i.i_item_id,
      i.i_item_sk,
      i.i_units,
      i.i_wholesale_cost,
      p.p_promo_id,
      p.p_purpose,
      c.c_customer_id,
      c.c_birth_country,
      sr.sr_return_amt
    FROM catalog_page cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    WHERE i.i_units IN ('Tbl', 'Pound')
      AND cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND p.p_purpose = 'Unknown'
  ),
  promo_item_full AS (
    SELECT p.p_promo_id, i.i_item_id
    FROM promotion p
    FULL OUTER JOIN item i ON p.p_item_sk = i.i_item_sk
  ),
  key_set_a AS (
    SELECT i.i_item_id FROM item i WHERE i.i_units = 'Tbl'
  ),
  key_set_b AS (
    SELECT i.i_item_id FROM item i WHERE i.i_wholesale_cost > 10
  ),
  diff_keys AS (
    SELECT * FROM key_set_a
    EXCEPT
    SELECT * FROM key_set_b
  )
SELECT
  combined.cp_catalog_page_id,
  combined.cs_order_number,
  combined.cs_quantity,
  combined.cs_net_profit,
  combined.i_item_id,
  combined.i_units,
  combined.i_wholesale_cost,
  combined.p_promo_id,
  combined.p_purpose,
  combined.c_customer_id,
  combined.c_birth_country,
  combined.sr_return_amt,
  combined.profit_rank,
  combined.max_sales_price,
  pif.p_promo_id AS promo_from_full_outer
FROM (
  SELECT
    bj.cp_catalog_page_id,
    bj.cs_order_number,
    bj.cs_quantity,
    bj.cs_net_profit,
    bj.i_item_id,
    bj.i_units,
    bj.i_wholesale_cost,
    bj.p_promo_id,
    bj.p_purpose,
    bj.c_customer_id,
    bj.c_birth_country,
    bj.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY bj.c_customer_id ORDER BY bj.cs_net_profit DESC) AS profit_rank,
    l.max_sales_price
  FROM base bj
  LEFT JOIN LATERAL (
    SELECT MAX(cs2.cs_ext_sales_price) AS max_sales_price
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = bj.i_item_sk
  ) l ON TRUE

  UNION DISTINCT

  SELECT
    bj2.cp_catalog_page_id,
    bj2.cs_order_number,
    bj2.cs_quantity,
    bj2.cs_net_profit,
    bj2.i_item_id,
    bj2.i_units,
    bj2.i_wholesale_cost,
    bj2.p_promo_id,
    bj2.p_purpose,
    bj2.c_customer_id,
    bj2.c_birth_country,
    bj2.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY bj2.c_customer_id ORDER BY bj2.cs_net_profit DESC) AS profit_rank,
    l2.max_sales_price
  FROM base bj2
  LEFT JOIN LATERAL (
    SELECT MAX(cs2.cs_ext_sales_price) AS max_sales_price
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = bj2.i_item_sk
  ) l2 ON TRUE
  WHERE bj2.i_units = 'Pound'
) AS combined
LEFT JOIN promo_item_full pif ON combined.i_item_id = pif.i_item_id
WHERE combined.profit_rank <= 5
  AND combined.i_item_id IN (SELECT i_item_id FROM diff_keys)
LIMIT 100
