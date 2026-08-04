WITH catalog AS (
      SELECT 
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_item_sk AS itm_sk,
        cs.cs_ext_sales_price AS sales_amt,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discount' ELSE 'No Discount' END AS discount_flag
      FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
      WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    ),
    store AS (
      SELECT 
        ss.ss_customer_sk AS cust_sk,
        ss.ss_item_sk AS itm_sk,
        ss.ss_ext_sales_price AS sales_amt,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_promo_sk AS promo_sk,
        CASE WHEN ss.ss_ext_discount_amt > 0 THEN 'Discount' ELSE 'No Discount' END AS discount_flag
      FROM store_sales ss TABLESAMPLE BERNOULLI (10)
      WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    ),
    combined AS (
      SELECT 
        c.cust_sk,
        c.itm_sk,
        c.sales_amt,
        c.discount_flag,
        c.promo_sk,
        'Catalog' AS source
      FROM catalog c
      UNION ALL
      SELECT 
        s.cust_sk,
        s.itm_sk,
        s.sales_amt,
        s.discount_flag,
        s.promo_sk,
        'Store' AS source
      FROM store s
    )
SELECT 
  cu.c_customer_id,
  it.i_item_id,
  cmb.source,
  cmb.sales_amt,
  cmb.discount_flag,
  CASE
    WHEN cmb.sales_amt > (
      SELECT avg(sales)
      FROM (
        SELECT sales_amt AS sales FROM combined
      ) a
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS sales_category
FROM combined cmb
JOIN customer cu ON cmb.cust_sk = cu.c_customer_sk
JOIN item it ON cmb.itm_sk = it.i_item_sk
WHERE EXISTS (
  SELECT 1
  FROM promotion p
  WHERE p.p_promo_sk = cmb.promo_sk
    AND p.p_discount_active = 'Y'
)
ORDER BY cmb.sales_amt DESC
LIMIT 100
