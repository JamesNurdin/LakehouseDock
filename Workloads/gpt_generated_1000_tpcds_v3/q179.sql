WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_net_profit,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        i.i_item_desc,
        i.i_color,
        p.p_promo_name,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 1998
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
      AND i.i_color LIKE 'R%'
      AND s.s_city LIKE '%ville%'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND regexp_like(p2.p_promo_name, 'Discount')
      )
)
SELECT
    concat('Store ', fs.s_store_name) AS store_label,
    fs.s_store_id,
    fs.s_city,
    sum(fs.ss_net_profit) AS total_net_profit,
    count(*) AS sales_count,
    (SELECT COUNT(*) FROM store_sales ss_all WHERE ss_all.ss_store_sk = fs.ss_store_sk) AS total_transactions,
    regexp_extract(max(fs.p_promo_name), '(\\w+)', 1) AS promo_keyword
FROM filtered_sales fs
GROUP BY
    fs.s_store_name,
    fs.s_store_id,
    fs.s_city,
    fs.ss_store_sk
HAVING sum(fs.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
