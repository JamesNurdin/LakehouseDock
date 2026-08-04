WITH
  cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
  ),
  ws AS (
    SELECT *
    FROM web_sales
    WHERE ws_quantity > 0
  ),
  joined AS (
    SELECT
      cs.cs_sold_date_sk                       AS cs_sold_date_sk,
      d_sold.d_year                            AS d_year,
      c_bill.c_customer_id                     AS c_customer_id,
      i.i_item_id                              AS i_item_id,
      p.p_promo_name                           AS p_promo_name,
      hd.hd_income_band_sk                     AS hd_income_band_sk,
      ib.ib_upper_bound                        AS ib_upper_bound,
      cs.cs_net_paid + COALESCE(ws.ws_net_paid, 0) AS total_net_paid
    FROM cs_sample cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm1
      ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2   -- same table reused under a different alias
      ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store st
      ON st.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = cs.cs_promo_sk
        AND p2.p_discount_active = 'Y'
    )
  ),
  agg AS (
    SELECT
      d_year,
      c_customer_id,
      i_item_id,
      p_promo_name,
      ib_upper_bound,
      SUM(total_net_paid) AS sum_net_paid,
      COUNT(*)           AS txn_cnt
    FROM joined
    GROUP BY GROUPING SETS (
      (d_year, c_customer_id),
      (i_item_id, p_promo_name),
      (c_customer_id, ib_upper_bound)
    )
  ),
  key_sub1 AS (
    SELECT c.c_customer_id, d.d_year
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(cs.cs_net_paid) > 2000
  ),
  key_sub2 AS (
    SELECT c.c_customer_id, d.d_year
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(cs.cs_net_paid) < 500
  ),
  key_set AS (
    SELECT c_customer_id, d_year FROM key_sub1
    INTERSECT
    SELECT c_customer_id, d_year FROM key_sub2
    EXCEPT
    SELECT c_customer_id, d_year FROM key_sub2
  )
SELECT
  a.d_year,
  a.c_customer_id,
  a.i_item_id,
  a.p_promo_name,
  a.ib_upper_bound,
  a.sum_net_paid,
  a.txn_cnt
FROM agg a
JOIN key_set ks
  ON a.c_customer_id = ks.c_customer_id
 AND a.d_year = ks.d_year
ORDER BY a.sum_net_paid DESC
OFFSET 0
LIMIT 100
