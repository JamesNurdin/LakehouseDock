WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      i.i_product_name,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
      SUM(cs.cs_ext_discount_amt) AS total_discount,
      ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
      CASE
        WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_category
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk, i.i_product_name
  ),
  returns_lateral AS (
    SELECT
      s.cs_item_sk,
      top.reason_desc,
      top.r_cnt
    FROM sales_agg s
    CROSS JOIN LATERAL (
      SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS r_cnt
      FROM store_returns sr
      JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
      WHERE sr.sr_item_sk = s.cs_item_sk
        AND sr.sr_returned_date_sk IN (
          SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2001
        )
      GROUP BY r.r_reason_desc
      ORDER BY r_cnt DESC
      LIMIT 1
    ) AS top
  ),
  intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_sales_price > 5000
    INTERSECT
    SELECT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d2
      ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND sr.sr_return_amt > 2000
  )
SELECT
  s.cs_item_sk,
  i.i_product_name,
  s.total_sales,
  s.distinct_customers,
  s.sales_category,
  rl.reason_desc,
  rl.r_cnt,
  COUNT(DISTINCT i.i_brand) OVER () AS distinct_brands_total,
  ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS overall_rank
FROM intersect_items ii
JOIN sales_agg s
  ON ii.item_sk = s.cs_item_sk
JOIN item i
  ON s.cs_item_sk = i.i_item_sk
JOIN returns_lateral rl
  ON s.cs_item_sk = rl.cs_item_sk
ORDER BY s.total_sales DESC
OFFSET 0 FETCH NEXT 20 ROWS ONLY
