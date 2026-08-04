WITH
  /* Sample the fact table */
  cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  /* Subquery 1 for INTERSECT */
  sub1 AS (
    SELECT cs.cs_order_number
    FROM cs
    WHERE cs.cs_quantity > 5
  ),

  /* Subquery 2 for INTERSECT */
  sub2 AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
  ),

  intersect_keys AS (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cr_order_number FROM sub2
  ),

  /* UNION of order numbers from two sources */
  union_keys AS (
    SELECT cs.cs_order_number FROM cs
    UNION
    SELECT cr.cr_order_number FROM catalog_returns cr
  ),

  /* EXCEPT: orders that appear in sales but not in store returns */
  except_keys AS (
    SELECT cs.cs_order_number FROM cs
    EXCEPT
    SELECT sr.sr_ticket_number FROM store_returns sr
  ),

  /* Core star‑join query that touches every selected table */
  final AS (
    SELECT
      cs.cs_order_number,
      d.d_year,
      i.i_category,
      i.i_class,
      cc.cc_name,
      cp.cp_type,
      w.w_warehouse_name,
      reason.r_reason_desc,
      COUNT(DISTINCT cs.cs_item_sk)               AS distinct_items,
      SUM(cs.cs_net_paid)                         AS total_net_paid,
      AVG(cs.cs_ext_discount_amt)                 AS avg_discount,
      MIN(cs.cs_net_paid)                         AS min_net_paid,
      MAX(cs.cs_net_paid)                         AS max_net_paid
    FROM cs
    JOIN date_dim d          ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t          ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i              ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr   ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason reason      ON sr.sr_reason_sk = reason.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim dr        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN web_page wp            ON wp.wp_creation_date_sk = d.d_date_sk
                                 AND wp.wp_customer_sk = c.c_customer_sk
    RIGHT OUTER JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_manufact = 'barantipri'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'Electronic'
      AND w.w_state = 'CA'
    GROUP BY
      cs.cs_order_number,
      d.d_year,
      i.i_category,
      i.i_class,
      cc.cc_name,
      cp.cp_type,
      w.w_warehouse_name,
      reason.r_reason_desc
  )
SELECT *
FROM final
WHERE cs_order_number IN (SELECT cs_order_number FROM intersect_keys)
   OR cs_order_number IN (SELECT cs_order_number FROM union_keys)
   OR cs_order_number IN (SELECT cs_order_number FROM except_keys)
