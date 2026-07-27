SELECT
    d.d_year AS year,
    i.i_category AS category,
    SUM(cs.cs_ext_sales_price) AS metric_amount,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT avg(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS avg_discount
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category
HAVING SUM(cs.cs_ext_sales_price) > 10000

UNION ALL

SELECT
    d.d_year AS year,
    i.i_category AS category,
    SUM(sr.sr_return_amt) AS metric_amount,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    (SELECT avg(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS avg_discount
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category
HAVING SUM(sr.sr_return_amt) > 5000

ORDER BY year, category, metric_amount DESC
LIMIT 100
