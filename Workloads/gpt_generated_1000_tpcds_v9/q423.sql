WITH
sales_agg AS (
  SELECT
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_item_sk AS item_sk,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    SUM(cs.cs_net_profit) AS net_profit
  FROM catalog_sales cs
  GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
),
returns_agg AS (
  SELECT
    sr.sr_customer_sk AS cust_sk,
    sr.sr_item_sk AS item_sk,
    SUM(sr.sr_return_amt) AS return_amount,
    SUM(sr.sr_net_loss) AS net_loss
  FROM store_returns sr
  GROUP BY sr.sr_customer_sk, sr.sr_item_sk
),
customer_sales AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    i.i_item_sk,
    s.sales_amount,
    s.net_profit,
    COALESCE(r.return_amount, 0) AS return_amount,
    COALESCE(r.net_loss, 0) AS net_loss,
    s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales_amount,
    s.net_profit - COALESCE(r.net_loss, 0) AS total_net_profit,
    CONCAT(i.i_brand, '-', i.i_item_id) AS item_code,
    REGEXP_EXTRACT(i.i_item_desc, '([A-Za-z]+)', 1) AS first_word_desc
  FROM sales_agg s
  JOIN customer c ON s.cust_sk = c.c_customer_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  LEFT JOIN returns_agg r
    ON s.cust_sk = r.cust_sk AND s.item_sk = r.item_sk
  WHERE i.i_brand LIKE 'B%'
    AND REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
    AND EXISTS (
      SELECT 1
      FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_url LIKE '%promo%'
    )
)
SELECT
  cs.c_customer_id,
  cs.c_first_name,
  cs.c_last_name,
  cs.i_category,
  cs.item_code,
  cs.first_word_desc,
  cs.sales_amount,
  cs.return_amount,
  cs.net_sales_amount,
  cs.total_net_profit,
  (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.i_item_sk
  ) AS avg_item_sales_price,
  RANK() OVER (PARTITION BY cs.i_category ORDER BY cs.total_net_profit DESC) AS category_rank
FROM customer_sales cs
ORDER BY cs.total_net_profit DESC, category_rank
LIMIT 100
