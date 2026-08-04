/* goal: Identify the most common first word of item descriptions for items whose product name contains 'Bicycle' and purchased/returned by customers whose first name starts with 'A', then aggregate distinct customers and net amounts per year. */
WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
),
sales_enhanced AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        cs.cs_net_paid AS net_amount,
        i.i_item_desc,
        i.i_product_name,
        c.c_first_name,
        c.c_last_name,
        l.first_word
    FROM sampled_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(i.i_item_desc, '^(\\w+)', 1) AS first_word
    ) l
    WHERE regexp_like(c.c_first_name, '^A.*')
      AND i.i_product_name LIKE '%Bicycle%'
      AND d.d_year = (
          SELECT max(d2.d_year)
          FROM tpcds.date_dim d2
          WHERE d2.d_year = 2000
      )
),
returns_enhanced AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        sr.sr_net_loss AS net_amount,
        i.i_item_desc,
        i.i_product_name,
        c.c_first_name,
        c.c_last_name,
        l.first_word
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(i.i_item_desc, '^(\\w+)', 1) AS first_word
    ) l
    WHERE regexp_like(c.c_first_name, '^A.*')
      AND i.i_product_name LIKE '%Bicycle%'
      AND d.d_year = (
          SELECT max(d2.d_year)
          FROM tpcds.date_dim d2
          WHERE d2.d_year = 2000
      )
)
SELECT
    u.year,
    u.first_word,
    COUNT(DISTINCT u.customer_id) AS distinct_customers,
    SUM(u.net_amount) AS total_net_amount
FROM (
    SELECT
        year,
        first_word,
        customer_id,
        net_amount
    FROM sales_enhanced
    UNION DISTINCT
    SELECT
        year,
        first_word,
        customer_id,
        -net_amount   -- treat return loss as negative revenue
    FROM returns_enhanced
) u
GROUP BY u.year, u.first_word
ORDER BY total_net_amount DESC
LIMIT 100
