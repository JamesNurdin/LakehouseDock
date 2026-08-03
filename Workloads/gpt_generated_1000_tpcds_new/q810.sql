WITH
  -- Expand each item description into its constituent words
  item_words AS (
    SELECT
      i.i_item_sk,
      i.i_item_desc,
      word
    FROM
      item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
  ),
  -- Full outer join of catalog sales and catalog returns on order number
  cat_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_bill_customer_sk,
      cs.cs_promo_sk,
      cs.cs_item_sk,
      cs.cs_net_profit,
      cr.cr_reason_sk,
      cr.cr_return_amount
    FROM
      catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  )

SELECT *
FROM (
  SELECT DISTINCT
    c.c_customer_id
  FROM
    cat_sales_returns csr
    LEFT JOIN promotion p
      ON csr.cs_promo_sk = p.p_promo_sk
    LEFT JOIN item i
      ON csr.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON csr.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN item_words iw
      ON i.i_item_sk = iw.i_item_sk
  WHERE
    p.p_promo_name LIKE '%Discount%'
    AND regexp_like(i.i_item_desc, '.*[A-Z]{3}.*')
    AND regexp_like(iw.word, '^[A-Z]{4}$')
    AND EXISTS (
      SELECT 1
      FROM reason r
      WHERE r.r_reason_sk = csr.cr_reason_sk
        AND regexp_like(r.r_reason_desc, '.*damage.*')
    )
) AS sub1
INTERSECT
SELECT *
FROM (
  SELECT DISTINCT
    c2.c_customer_id
  FROM
    store_sales ss
    LEFT JOIN item i2
      ON ss.ss_item_sk = i2.i_item_sk
    LEFT JOIN customer c2
      ON ss.ss_customer_sk = c2.c_customer_sk
    LEFT JOIN item_words iw2
      ON i2.i_item_sk = iw2.i_item_sk
  WHERE
    i2.i_item_desc LIKE '%BRAND%'
    AND regexp_like(iw2.word, '^[A-Z]{4}$')
    AND ss.ss_net_paid > 5000
) AS sub2
LIMIT 100
