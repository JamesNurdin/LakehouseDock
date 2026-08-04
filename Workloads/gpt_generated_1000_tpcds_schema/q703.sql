WITH
  sales_agg AS (
    SELECT
      ws_item_sk,
      ws_promo_sk,
      SUM(ws_net_profit) AS total_net_profit,
      SUM(ws_quantity) AS total_quantity,
      COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_sold_time_sk > 20000
    GROUP BY ws_item_sk, ws_promo_sk
  ),
  returns_agg AS (
    SELECT
      wr_item_sk,
      MIN(wr_reason_sk) AS reason_sk,
      SUM(wr_return_quantity) AS total_return_qty,
      SUM(wr_net_loss) AS total_net_loss
    FROM web_returns TABLESAMPLE BERNOULLI (10)
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY wr_item_sk
  ),
  joined_data AS (
    SELECT
      i.i_item_id,
      i.i_manufact,
      p.p_promo_name,
      p.p_cost,
      r.r_reason_desc,
      s.total_net_profit,
      s.total_quantity,
      ra.total_return_qty,
      ra.total_net_loss
    FROM sales_agg s
    JOIN returns_agg ra ON s.ws_item_sk = ra.wr_item_sk
    JOIN item i ON i.i_item_sk = s.ws_item_sk
    JOIN promotion p ON p.p_promo_sk = s.ws_promo_sk
    JOIN reason r ON r.r_reason_sk = ra.reason_sk
    WHERE i.i_rec_start_date > DATE '2000-01-01'
      AND p.p_cost > 500
      AND r.r_reason_desc LIKE '%color%'
  ),
  intersect_items AS (
    SELECT i_item_id FROM item WHERE i_brand_id IN (1, 2, 3)
    INTERSECT
    SELECT i_item_id FROM item WHERE i_category_id IN (10, 20)
  ),
  except_orders AS (
    SELECT ws_order_number FROM web_sales
    EXCEPT
    SELECT wr_order_number FROM web_returns
  ),
  final_union AS (
    SELECT
      jd.i_item_id,
      jd.i_manufact,
      jd.p_promo_name,
      jd.total_net_profit,
      jd.total_quantity,
      jd.total_return_qty,
      jd.total_net_loss,
      ROW_NUMBER() OVER (ORDER BY jd.total_net_profit DESC) AS rn
    FROM joined_data jd
    WHERE jd.i_item_id IN (SELECT i_item_id FROM intersect_items)
    UNION
    SELECT
      jd.i_item_id,
      jd.i_manufact,
      jd.p_promo_name,
      jd.total_net_profit,
      jd.total_quantity,
      jd.total_return_qty,
      jd.total_net_loss,
      ROW_NUMBER() OVER (ORDER BY jd.total_net_profit DESC) AS rn
    FROM joined_data jd
    WHERE jd.i_item_id NOT IN (SELECT i_item_id FROM intersect_items)
  )
SELECT
  fu.i_item_id,
  fu.i_manufact,
  fu.p_promo_name,
  fu.total_net_profit,
  fu.total_quantity,
  fu.total_return_qty,
  fu.total_net_loss,
  fu.rn,
  (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales) AS distinct_customers
FROM final_union fu
WHERE fu.rn <= 100
ORDER BY fu.total_net_profit DESC
LIMIT 100
