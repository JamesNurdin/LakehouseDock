WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_category,
        i_brand,
        i_item_id,
        regexp_extract(i_item_id, '([A-Z]+[0-9]+)', 1) AS extracted_code
    FROM
        item
    WHERE
        regexp_like(i_item_desc, '(?i)special')
)
SELECT
    concat(s.s_store_name, ' - ', s.s_city) AS store_location,
    substring(s.s_store_name, 1, 5) AS store_name_prefix,
    fi.i_category,
    fi.i_brand,
    fi.extracted_code,
    sum(ss.ss_net_profit) AS total_net_profit,
    count(distinct ss.ss_ticket_number) AS distinct_transactions,
    avg(ss.ss_quantity) AS avg_quantity_per_txn
FROM
    store_sales ss
    INNER JOIN filtered_items fi
        ON ss.ss_item_sk = fi.i_item_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    s.s_store_name LIKE '%Market%'
    AND d.d_year = 1998
    AND regexp_like(p.p_promo_name, '(?i)clearance')
GROUP BY
    concat(s.s_store_name, ' - ', s.s_city),
    substring(s.s_store_name, 1, 5),
    fi.i_category,
    fi.i_brand,
    fi.extracted_code
ORDER BY
    total_net_profit DESC
LIMIT 100
