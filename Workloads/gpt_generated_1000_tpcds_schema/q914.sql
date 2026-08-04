WITH
  cs_agg AS (
    SELECT
      i.i_item_id,
      d_sales.d_year,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sales
      ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
      ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
      ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE cs.cs_item_sk IN (
      SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red'
    )
    GROUP BY i.i_item_id, d_sales.d_year
  ),
  ws_agg AS (
    SELECT
      i.i_item_id,
      d_ws.d_year,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
      ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
      ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY i.i_item_id, d_ws.d_year
  ),
  returns_agg AS (
    SELECT
      i.i_item_id,
      d_ret.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    GROUP BY i.i_item_id, d_ret.d_year
  ),
  inventory_sample AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    TABLESAMPLE BERNOULLI (10)
  ),
  combined_sales AS (
    SELECT i_item_id, d_year, total_net_paid, sales_cnt FROM cs_agg
    UNION
    SELECT i_item_id, d_year, total_net_paid, sales_cnt FROM ws_agg
  ),
  sales_minus_returns AS (
    SELECT
      cs.i_item_id,
      cs.d_year,
      cs.total_net_paid - COALESCE(r.total_return_amount, 0) AS net_after_returns,
      cs.sales_cnt - COALESCE(r.return_cnt, 0) AS net_sales_cnt
    FROM combined_sales cs
    LEFT JOIN returns_agg r
      ON cs.i_item_id = r.i_item_id AND cs.d_year = r.d_year
  ),
  final_set AS (
    SELECT i_item_id FROM cs_agg
    INTERSECT
    SELECT i_item_id FROM ws_agg
  ),
  excluded_items AS (
    SELECT i_item_id FROM cs_agg
    EXCEPT
    SELECT i_item_id FROM returns_agg
  )
SELECT
  s.i_item_id,
  s.d_year,
  s.net_after_returns,
  s.net_sales_cnt,
  i.i_brand,
  i.i_category
FROM sales_minus_returns s
JOIN item i
  ON s.i_item_id = i.i_item_id
JOIN final_set f
  ON s.i_item_id = f.i_item_id
JOIN excluded_items e
  ON s.i_item_id = e.i_item_id
ORDER BY s.net_after_returns DESC
LIMIT 100
