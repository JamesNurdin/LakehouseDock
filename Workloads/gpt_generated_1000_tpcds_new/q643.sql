WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    h.hd_demo_sk,
    CASE WHEN s.cs_quantity > 10 THEN 'High' ELSE 'Low' END AS qty_category,
    d.d_year
FROM sampled_sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics h ON s.cs_bill_hdemo_sk = h.hd_demo_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND p.p_channel_demo = 'N'
EXCEPT
SELECT
    h2.hd_demo_sk,
    CASE WHEN r.wr_return_quantity > 5 THEN 'High' ELSE 'Low' END AS qty_category,
    d2.d_year
FROM web_returns r
JOIN date_dim d2 ON r.wr_returned_date_sk = d2.d_date_sk
JOIN household_demographics h2 ON r.wr_refunded_hdemo_sk = h2.hd_demo_sk
WHERE d2.d_year = 2001
ORDER BY hd_demo_sk
LIMIT 100
