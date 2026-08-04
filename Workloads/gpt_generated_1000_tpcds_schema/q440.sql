WITH
  -- Sample a fraction of catalog_sales
  sampled_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid_inc_tax
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)  -- 10% random sample
    WHERE cs.cs_net_paid_inc_tax > 500
  ),
  -- Aggregate the sampled sales by calendar date
  sales_agg AS (
    SELECT d.d_date,
           SUM(ss.cs_quantity) AS total_qty
    FROM sampled_sales ss
    JOIN date_dim d
      ON ss.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
  ),
  -- Keys from store returns for the year 2001
  store_ret AS (
    SELECT sr.sr_customer_sk   AS customer_key,
           sr.sr_returned_date_sk AS date_key
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  -- Keys from web returns for the year 2001
  web_ret AS (
    SELECT wr.wr_refunded_customer_sk AS customer_key,
           wr.wr_returned_date_sk   AS date_key
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  -- Keys appearing in both store and web returns (INTERSECT)
  common_keys AS (
    SELECT customer_key, date_key FROM store_ret
    INTERSECT
    SELECT customer_key, date_key FROM web_ret
  ),
  -- Full outer join of the two key sets, keeping unmatched rows (FULL OUTER JOIN)
  full_joined AS (
    SELECT COALESCE(s.customer_key, w.customer_key) AS customer_key,
           COALESCE(s.date_key, w.date_key)       AS date_key,
           CASE
             WHEN s.customer_key IS NOT NULL AND w.customer_key IS NOT NULL THEN 'both'
             WHEN s.customer_key IS NOT NULL THEN 'store'
             ELSE 'web'
           END AS source
    FROM store_ret s
    FULL OUTER JOIN web_ret w
      ON s.customer_key = w.customer_key
     AND s.date_key    = w.date_key
  ),
  -- Combine the intersected set with the full outer join set and subtract a filtered key set (EXCEPT)
  final_set AS (
    SELECT customer_key, date_key FROM common_keys
    UNION ALL
    SELECT customer_key, date_key FROM full_joined
    EXCEPT
    SELECT sr.sr_customer_sk, sr.sr_returned_date_sk
    FROM store_returns sr
    WHERE sr.sr_reversed_charge > 1000
  )
SELECT f.customer_key,
       f.date_key,
       d.d_year AS return_year,
       COALESCE(sa.total_qty, 0) AS sales_quantity
FROM final_set f
JOIN date_dim d
  ON f.date_key = d.d_date_sk
LEFT JOIN sales_agg sa
  ON d.d_date = sa.d_date
WHERE EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = f.customer_key
          AND c.c_preferred_cust_flag = 'Y'
      )
ORDER BY f.customer_key ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
