WITH sampled_items AS (
  SELECT i.i_item_sk,
         i.i_product_name,
         i.i_manager_id
  FROM item i TABLESAMPLE BERNOULLI (10)
),
item_promos AS (
  SELECT si.i_item_sk,
         si.i_product_name,
         p.p_promo_name,
         p.p_cost,
         CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
  FROM sampled_items si
  LEFT JOIN promotion p ON p.p_item_sk = si.i_item_sk
),
item_returns AS (
  SELECT wr.wr_item_sk,
         COUNT(*) AS return_cnt,
         SUM(wr.wr_return_amt) AS total_return_amt
  FROM web_returns wr
  GROUP BY wr.wr_item_sk
),
full_items AS (
  SELECT ip.i_item_sk,
         ip.i_product_name,
         ip.p_promo_name,
         ip.promo_status,
         ir.return_cnt,
         ir.total_return_amt,
         (
           SELECT SUM(wr2.wr_refunded_cash)
           FROM web_returns wr2
           WHERE wr2.wr_item_sk = ip.i_item_sk
         ) AS total_refunded_cash
  FROM item_promos ip
  FULL OUTER JOIN item_returns ir ON ir.wr_item_sk = ip.i_item_sk
)
(
  SELECT fi.i_item_sk,
         fi.i_product_name,
         fi.p_promo_name,
         fi.promo_status,
         COALESCE(fi.return_cnt, 0) AS return_cnt,
         COALESCE(fi.total_return_amt, 0) AS total_return_amt,
         COALESCE(fi.total_refunded_cash, 0) AS total_refunded_cash
  FROM full_items fi
  WHERE fi.i_item_sk IS NOT NULL
)
EXCEPT
(
  SELECT i.i_item_sk,
         i.i_product_name,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  FROM item i
  WHERE i.i_manager_id = 3
)
UNION ALL
(
  SELECT si.i_item_sk,
         si.i_product_name,
         NULL AS p_promo_name,
         'No Promo/Return' AS promo_status,
         0 AS return_cnt,
         0.0 AS total_return_amt,
         0.0 AS total_refunded_cash
  FROM sampled_items si
  WHERE NOT EXISTS (
    SELECT 1 FROM full_items fi2 WHERE fi2.i_item_sk = si.i_item_sk
  )
)
ORDER BY i_item_sk
LIMIT 100
