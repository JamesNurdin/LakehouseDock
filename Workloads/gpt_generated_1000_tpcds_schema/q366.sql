WITH sampled_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_sold_date_sk,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_quantity
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_sold_date_sk IS NOT NULL
),
filtered_sales AS (
    SELECT ss.cs_item_sk,
           ss.cs_net_paid,
           ss.cs_net_profit,
           ss.cs_quantity,
           i.i_brand,
           i.i_item_desc,
           dd.d_date
    FROM sampled_sales ss
    JOIN item i ON ss.cs_item_sk = i.i_item_sk
    JOIN date_dim dd ON ss.cs_sold_date_sk = dd.d_date_sk
    WHERE dd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND regexp_like(i.i_item_desc, '[A-Za-z]{3}[0-9]{2}')
      AND i.i_item_desc LIKE '%BRAND%'
),
 sold_item_keys AS (
    SELECT DISTINCT cs_item_sk AS i_item_sk
    FROM filtered_sales
),
 returned_item_keys AS (
    SELECT DISTINCT cr_item_sk AS i_item_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk IS NOT NULL
),
 non_returned_items AS (
    SELECT i_item_sk
    FROM sold_item_keys
    EXCEPT
    SELECT i_item_sk
    FROM returned_item_keys
)
SELECT
    concat(i.i_brand, ' ', i.i_item_desc) AS product_name,
    i.i_item_sk,
    SUM(f.cs_net_paid) AS total_paid,
    SUM(f.cs_quantity) AS total_quantity,
    CASE
        WHEN SUM(f.cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_indicator
FROM filtered_sales f
JOIN item i ON f.cs_item_sk = i.i_item_sk
JOIN non_returned_items nri ON i.i_item_sk = nri.i_item_sk
GROUP BY i.i_item_sk, i.i_brand, i.i_item_desc
ORDER BY total_paid DESC
LIMIT 100
