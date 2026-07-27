WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_product_name,
        i.i_brand,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS extracted_number,
        CASE
            WHEN regexp_like(i.i_item_desc, '^.*[0-9]{3}.*$') THEN 'Has3Digit'
            ELSE 'No3Digit'
        END AS digit_flag
    FROM
        item i
    WHERE
        i.i_item_desc LIKE '%SIZE%'
        AND regexp_like(i.i_item_desc, '(?i)size')
)
SELECT
    CONCAT(s.s_store_name, ' (', f.digit_flag, ')') AS store_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount_total
FROM
    filtered_items f
    JOIN store_sales ss ON ss.ss_item_sk = f.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
GROUP BY
    CONCAT(s.s_store_name, ' (', f.digit_flag, ')')
ORDER BY
    total_net_profit DESC
LIMIT 100
