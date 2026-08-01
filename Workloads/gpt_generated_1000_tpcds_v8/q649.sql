WITH
  c_sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_net_paid,
      i.i_item_id,
      p.p_channel_dmail
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_start_date_sk BETWEEN 2450123 AND 2450895
  ),
  s_returns_full AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      i.i_item_id,
      s.s_store_name
    FROM tpcds.item i
    FULL OUTER JOIN tpcds.store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
  ),
  cross_joined AS (
    SELECT d.p_channel_dmail, v.num
    FROM (SELECT DISTINCT p_channel_dmail FROM tpcds.promotion) d
    CROSS JOIN (VALUES 1, 2, 3) AS v(num)
  ),
  union_agg AS (
    SELECT i_id AS item_id,
           COUNT(DISTINCT order_num) AS distinct_orders,
           SUM(DISTINCT net_paid) AS total_distinct_net_paid,
           0 AS distinct_returns,
           0.0 AS total_distinct_return_amt
    FROM (
      SELECT i.i_item_id AS i_id,
             cs.cs_order_number AS order_num,
             cs.cs_net_paid AS net_paid
      FROM c_sales cs
      JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    ) sub1
    GROUP BY i_id
    UNION ALL
    SELECT i_id AS item_id,
           0,
           0.0,
           COUNT(DISTINCT ticket_num) AS distinct_returns,
           SUM(DISTINCT return_amt) AS total_distinct_return_amt
    FROM (
      SELECT i.i_item_id AS i_id,
             sr.sr_ticket_number AS ticket_num,
             sr.sr_return_amt AS return_amt
      FROM s_returns_full sr
      JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    ) sub2
    GROUP BY i_id
  ),
  filtered AS (
    SELECT *
    FROM union_agg
    EXCEPT
    SELECT i_item_id, NULL, NULL, NULL, NULL
    FROM (
      SELECT i.i_item_id
      FROM tpcds.web_returns wr
      JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
      WHERE wr.wr_return_amt > 500
    ) web_items
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY f.item_id) AS row_num,
  f.item_id,
  f.distinct_orders,
  f.total_distinct_net_paid,
  f.distinct_returns,
  f.total_distinct_return_amt,
  cj.p_channel_dmail,
  cj.num
FROM filtered f
CROSS JOIN cross_joined cj
ORDER BY row_num
LIMIT 100
