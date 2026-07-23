WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        i.i_brand,
        i.i_item_desc,
        i.i_class,
        s.s_store_name,
        t.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
      AND lower(i.i_item_desc) LIKE '%shirt%'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    s_store_name,
    i_class,
    concat(i_brand, ' - ', i_item_desc) AS brand_item_desc,
    substring(i_item_desc, 1, 20) AS short_desc,
    regexp_extract(i_item_desc, '([0-9]+)', 1) AS numeric_part,
    sum(ss_net_paid) AS total_net_paid,
    count(*) AS sales_count
FROM filtered_sales
GROUP BY
    s_store_name,
    i_class,
    concat(i_brand, ' - ', i_item_desc),
    substring(i_item_desc, 1, 20),
    regexp_extract(i_item_desc, '([0-9]+)', 1)
HAVING sum(ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
