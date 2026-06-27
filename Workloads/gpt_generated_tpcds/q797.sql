SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    COUNT(*) AS sales_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_per_sale,
    COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promotions_used
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
GROUP BY d.d_year, d.d_moy, i.i_category
ORDER BY d.d_year, d.d_moy, i.i_category
