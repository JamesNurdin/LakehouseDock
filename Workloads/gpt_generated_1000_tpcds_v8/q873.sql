WITH
  -- Join all ten tables in a left‑deep chain with required filters
  joined_data AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cp.cp_catalog_number,
      cs.cs_sold_date_sk,
      cs.cs_quantity,
      cs.cs_sales_price,
      cs.cs_net_profit,
      cs.cs_net_paid,
      d.d_year,
      c.c_customer_sk,
      c.c_customer_id,
      ca.ca_state,
      cd.cd_gender,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      r.r_reason_desc,
      wp.wp_web_page_sk,
      wp.wp_url,
      wr.wr_return_quantity AS wr_ret_qty,
      wr.wr_return_amt AS wr_ret_amt
    FROM catalog_page cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
      d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND cs.cs_quantity > 5
      AND wr.wr_return_amt > 100
  ),

  -- LATERAL subquery that builds an array from two numeric columns and UNNESTs it
  expanded_metrics AS (
    SELECT
      jd.*,
      metric
    FROM joined_data jd
    CROSS JOIN LATERAL (
      SELECT ARRAY[ jd.cs_quantity, CAST(jd.cs_sales_price AS double) ] AS arr
    ) arr_tbl
    CROSS JOIN UNNEST(arr_tbl.arr) AS t(metric)
  ),

  -- Two subqueries whose key sets will be intersected
  intersect_ids AS (
    SELECT c.c_customer_id
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT c.c_customer_id
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_quantity > 1
  ),

  -- Uncorrelated subquery for the anti‑semi‑join
  anti_ids AS (
    SELECT c.c_customer_id
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity > 10
  )

SELECT
  em.c_customer_id,
  em.r_reason_desc,
  SUM(em.cs_net_paid)               AS total_net_paid,
  AVG(em.cs_net_profit)             AS avg_profit,
  COUNT(*)                           AS txn_count,
  CASE WHEN SUM(em.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  MIN(em.metric)                    AS min_metric,
  MAX(em.metric)                    AS max_metric
FROM expanded_metrics em
WHERE em.c_customer_id IN (SELECT c_customer_id FROM intersect_ids)
  AND em.c_customer_id NOT IN (SELECT c_customer_id FROM anti_ids)
GROUP BY ROLLUP (em.c_customer_id, em.r_reason_desc)
ORDER BY total_net_paid DESC
LIMIT 100
