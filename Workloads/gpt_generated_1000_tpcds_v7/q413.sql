SELECT
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    CONCAT(substr(i.i_color, 1, 3), CAST(d.d_year AS varchar)) AS color_year_code
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE regexp_like(i.i_item_desc, '(?i)BRUSH')
  AND p.p_promo_name LIKE 'Holiday%'
  AND i.i_brand LIKE 'Brand%'
GROUP BY p.p_promo_name, d.d_year, d.d_month_seq, i.i_color
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
