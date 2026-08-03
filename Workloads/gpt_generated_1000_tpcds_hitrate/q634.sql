WITH
  sales_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year AS year,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      SUM(ss.ss_net_profit) AS profit_amount,
      COUNT(*) AS txn_cnt,
      CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY CUBE (s.s_store_id, d.d_year)
  ),
  returns_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year AS year,
      SUM(sr.sr_return_amt_inc_tax) * -1 AS sales_amount,
      SUM(sr.sr_net_loss) * -1 AS profit_amount,
      COUNT(*) AS txn_cnt,
      CASE WHEN SUM(sr.sr_net_loss) > 30000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY CUBE (s.s_store_id, d.d_year)
  ),
  full_sales_returns AS (
    SELECT
      COALESCE(sa.store_id, ra.store_id) AS store_id,
      COALESCE(sa.year, ra.year) AS year,
      COALESCE(sa.sales_amount, 0) AS sales_amount,
      COALESCE(ra.sales_amount, 0) AS returns_amount,
      COALESCE(sa.profit_amount, 0) AS profit_amount,
      COALESCE(ra.profit_amount, 0) AS returns_profit,
      CASE
        WHEN sa.store_id IS NULL THEN 'ReturnOnly'
        WHEN ra.store_id IS NULL THEN 'SalesOnly'
        ELSE 'Both'
      END AS source_type,
      COALESCE(sa.profit_category, ra.profit_category) AS profit_category
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
      ON sa.store_id = ra.store_id AND sa.year = ra.year
  ),
  union_set AS (
    SELECT store_id, year, sales_amount, profit_amount, txn_cnt, profit_category FROM sales_agg
    UNION ALL
    SELECT store_id, year, sales_amount, profit_amount, txn_cnt, profit_category FROM returns_agg
  ),
  categories AS (
    SELECT 'High'   AS cat UNION ALL
    SELECT 'Low'    AS cat UNION ALL
    SELECT 'Medium' AS cat
  ),
  final_set AS (
    SELECT
      f.store_id,
      f.year,
      f.sales_amount,
      f.returns_amount,
      f.profit_amount,
      f.returns_profit,
      f.source_type,
      f.profit_category,
      cat.cat,
      (SELECT AVG(sales_amount) FROM union_set) AS avg_sales,
      CASE WHEN f.sales_amount > (SELECT AVG(sales_amount) FROM union_set) THEN 1 ELSE 0 END AS above_avg_flag
    FROM full_sales_returns f
    CROSS JOIN categories cat
    WHERE cat.cat = f.profit_category OR cat.cat = 'Medium'
  )
SELECT
  store_id,
  year,
  sales_amount,
  returns_amount,
  profit_amount,
  returns_profit,
  source_type,
  profit_category,
  cat,
  avg_sales,
  above_avg_flag
FROM final_set
ORDER BY store_id, year
OFFSET 5 ROWS FETCH NEXT 15 ROWS ONLY
