WITH
  filtered_items AS (
    SELECT
      i_item_sk,
      i_item_desc,
      regexp_extract(i_item_desc, '(\\d{4})', 1) AS model_year
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (5)
    WHERE regexp_like(i_item_desc, '[A-Z]{2}[0-9]{4}')
  ),
  sales_union AS (
    SELECT
      ss.ss_customer_sk          AS c_customer_sk,
      ss.ss_net_paid            AS net_paid,
      i.i_item_desc,
      ss.ss_sold_date_sk        AS sold_date_sk
    FROM tpcds.store_sales ss
    JOIN filtered_items i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_first_name LIKE 'A%'
      AND c.c_last_name LIKE '%son'
    UNION DISTINCT
    SELECT
      ws.ws_bill_customer_sk    AS c_customer_sk,
      ws.ws_net_paid            AS net_paid,
      i.i_item_desc,
      ws.ws_sold_date_sk        AS sold_date_sk
    FROM tpcds.web_sales ws
    JOIN filtered_items i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_first_name LIKE 'A%'
      AND c.c_last_name LIKE '%son'
  ),
  returns_customers AS (
    SELECT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM tpcds.catalog_returns cr
    JOIN filtered_items i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_refunded_cash > 1000
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM sales_union
    INTERSECT
    SELECT c_customer_sk FROM returns_customers
  ),
  final_agg AS (
    SELECT
      su.c_customer_sk,
      SUM(su.net_paid)                     AS total_net_paid,
      COUNT(*)                              AS purchase_cnt,
      MAX(su.i_item_desc)                  AS any_item_desc,
      ROW_NUMBER() OVER (PARTITION BY su.c_customer_sk ORDER BY SUM(su.net_paid) DESC) AS rn_customer,
      ROW_NUMBER() OVER (ORDER BY SUM(su.net_paid) DESC)                         AS global_rank
    FROM (
      SELECT c_customer_sk, net_paid, i_item_desc
      FROM sales_union
    ) su
    WHERE su.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
    GROUP BY su.c_customer_sk
  )
SELECT
  fa.c_customer_sk,
  fa.total_net_paid,
  fa.purchase_cnt,
  fa.any_item_desc,
  fa.rn_customer,
  fa.global_rank,
  (SELECT AVG(net_paid) FROM sales_union)                     AS avg_net_paid_all,
  p.p_promo_name
FROM final_agg fa
CROSS JOIN LATERAL (
  SELECT p.p_promo_name
  FROM tpcds.promotion p
  WHERE regexp_like(p.p_promo_name, '.*Sale.*')
  LIMIT 1
) p
ORDER BY fa.total_net_paid DESC
LIMIT 100
