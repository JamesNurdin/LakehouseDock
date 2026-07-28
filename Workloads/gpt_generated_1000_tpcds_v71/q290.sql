WITH filtered_sales AS (
    SELECT
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_brand,
        i.i_color,
        i.i_item_desc,
        p.p_promo_name,
        d.d_year,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)soft|hard')
      AND p.p_promo_name LIKE '%discount%'
      AND d.d_year = 2002
)
SELECT
    brand_color,
    p_promo_name,
    d_year,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
FROM filtered_sales
GROUP BY brand_color, p_promo_name, d_year
ORDER BY total_net_paid DESC
LIMIT 100
