WITH
  sales_agg AS (
    SELECT
      s.s_store_id,
      p.p_promo_id,
      t.t_hour,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 1
      AND ss.ss_net_profit > 0
      AND ca.ca_gmt_offset = -5.00
    GROUP BY ROLLUP (s.s_store_id, p.p_promo_id, t.t_hour)
  ),
  returns_agg AS (
    SELECT
      ca.ca_state AS ret_state,
      t.t_hour AS ret_hour,
      SUM(wr.wr_return_amt) AS total_return_amt,
      SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND t.t_hour BETWEEN 9 AND 17
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_net_loss > 0
      AND wr.wr_fee < 100
    GROUP BY ROLLUP (ca.ca_state, t.t_hour)
  ),
  full_join_sales_returns AS (
    SELECT
      COALESCE(sa.s_store_id, ra.ret_state) AS key_entity,
      sa.p_promo_id,
      sa.t_hour,
      sa.total_sales,
      sa.total_profit,
      ra.total_return_amt,
      ra.total_net_loss
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
      ON sa.t_hour = ra.ret_hour
     AND sa.s_store_id = ra.ret_state
  ),
  sales_topk AS (
    SELECT
      s_store_id,
      p_promo_id,
      t_hour,
      total_sales,
      total_profit,
      ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS rn
    FROM sales_agg
    WHERE s_store_id IS NOT NULL AND p_promo_id IS NOT NULL
  ),
  sales_ranked AS (
    SELECT s_store_id, p_promo_id, t_hour, total_sales, total_profit
    FROM sales_topk
    WHERE rn <= 3
  ),
  set_a AS (
    SELECT s_store_id FROM store WHERE s_state = 'CA'
  ),
  set_b AS (
    SELECT s_store_id FROM store WHERE s_number_employees > 50
  ),
  except_set AS (
    SELECT s_store_id FROM set_a
    EXCEPT
    SELECT s_store_id FROM set_b
  ),
  intersect_set AS (
    SELECT s_store_id FROM set_a
    INTERSECT
    SELECT s_store_id FROM set_b
  ),
  union_src AS (
    SELECT
      key_entity,
      p_promo_id,
      t_hour,
      total_sales,
      total_profit,
      total_return_amt,
      total_net_loss
    FROM full_join_sales_returns
    WHERE key_entity IS NOT NULL
    UNION
    SELECT
      s_store_id AS key_entity,
      p_promo_id,
      t_hour,
      total_sales,
      total_profit,
      NULL AS total_return_amt,
      NULL AS total_net_loss
    FROM sales_ranked
    UNION
    SELECT s_store_id AS key_entity, NULL, NULL, NULL, NULL, NULL, NULL FROM except_set
    UNION
    SELECT s_store_id AS key_entity, NULL, NULL, NULL, NULL, NULL, NULL FROM intersect_set
  ),
  final_ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY key_entity ORDER BY total_sales DESC NULLS LAST) AS rn
    FROM union_src
  )
SELECT
  key_entity,
  p_promo_id,
  t_hour,
  total_sales,
  total_profit,
  total_return_amt,
  total_net_loss,
  rn AS rank_in_entity
FROM final_ranked
WHERE rn <= 5
ORDER BY key_entity, rn
LIMIT 100
