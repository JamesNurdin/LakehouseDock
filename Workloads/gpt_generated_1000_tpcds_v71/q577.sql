WITH filtered_stores AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        CONCAT(s.s_city, ', ', s.s_state) AS location
    FROM store AS s
    WHERE REGEXP_LIKE(s.s_store_name, '(?i)market|store')
)
SELECT
    fs.s_store_name,
    fs.location,
    d.d_year,
    CONCAT(fs.s_store_name, ' (', fs.location, ')') AS store_full_name,
    SUBSTRING(i.i_item_desc FROM 1 FOR 15) AS item_prefix,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1) AS promo_discount_pct,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM filtered_stores AS fs
JOIN store_sales AS ss
    ON ss.ss_store_sk = fs.s_store_sk
JOIN date_dim AS d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item AS i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion AS p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE i.i_item_desc LIKE '%BRICK%'
  AND REGEXP_LIKE(p.p_promo_name, '(?i)SAVE[[:space:]]*\\d+%')
GROUP BY
    fs.s_store_name,
    fs.location,
    d.d_year,
    SUBSTRING(i.i_item_desc FROM 1 FOR 15),
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1)
ORDER BY total_net_paid DESC
LIMIT 100
