SELECT
    concat_ws('|', pm.slug, ed.domain, date_format(d.d_date, '%Y%m%d')) AS composite_key,
    pm.i_product_name,
    pm.slug,
    pm.name_len,
    pm.word_cnt,
    round(pm.vowel_ratio, 3) AS vowel_ratio,
    ed.domain,
    date_format(d.d_date, '%Y-%m-%d') AS sold_date,
    sum(ss.ss_net_profit) AS total_profit,
    count(*) AS sales_cnt,
    avg(ss.ss_quantity) AS avg_quantity,
    approx_percentile(ss.ss_net_paid, 0.5) AS median_net_paid,
    max(ss.ss_net_paid) AS max_net_paid,
    min(ss.ss_net_paid) AS min_net_paid
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN (
    SELECT
        i_item_sk,
        i_product_name,
        lower(replace(i_product_name, ' ', '-')) AS slug,
        length(i_product_name) AS name_len,
        cardinality(split(i_product_name, ' ')) AS word_cnt,
        length(regexp_replace(i_product_name, '[^aeiouAEIOU]', '')) AS vowel_cnt,
        (length(regexp_replace(i_product_name, '[^aeiouAEIOU]', '')) * 1.0) / nullif(length(i_product_name), 0) AS vowel_ratio
    FROM item
) pm ON i.i_item_sk = pm.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN (
    SELECT
        c_customer_sk,
        lower(regexp_extract(c_email_address, '@(.*)$', 1)) AS domain
    FROM customer
) ed ON c.c_customer_sk = ed.c_customer_sk
WHERE pm.word_cnt >= 2
  AND ed.domain IS NOT NULL
  AND d.d_year BETWEEN 1998 AND 2002
GROUP BY
    concat_ws('|', pm.slug, ed.domain, date_format(d.d_date, '%Y%m%d')),
    pm.i_product_name,
    pm.slug,
    pm.name_len,
    pm.word_cnt,
    pm.vowel_ratio,
    ed.domain,
    date_format(d.d_date, '%Y-%m-%d')
HAVING sum(ss.ss_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 20
