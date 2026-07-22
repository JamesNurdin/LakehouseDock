WITH filtered_items AS (
    SELECT DISTINCT
        i.i_item_sk,
        i.i_category,
        i.i_item_desc,
        SUBSTRING(i.i_item_desc FROM 1 FOR 30) AS short_desc
    FROM
        item i
    WHERE
        regexp_like(i.i_item_desc, '(?i)Chocolate|Fruit')
),
sales_with_address AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ca.ca_city
    FROM
        store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_city LIKE 'A%'
)
SELECT
    CONCAT(s.s_store_name, ' (', s.s_city, ')') AS store_location,
    fi.i_category,
    fi.short_desc,
    COUNT(DISTINCT sw.ss_customer_sk) AS distinct_customers,
    SUM(sw.ss_quantity) AS total_quantity,
    SUM(sw.ss_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(sw.ss_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(sw.ss_net_profit) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_bucket,
    CASE
        WHEN regexp_like(fi.i_item_desc, '(?i)^Chocolate') THEN 'CHOCOLATE'
        ELSE 'OTHER'
    END AS item_type_flag
FROM
    sales_with_address sw
JOIN filtered_items fi
    ON sw.ss_item_sk = fi.i_item_sk
JOIN store s
    ON sw.ss_store_sk = s.s_store_sk
GROUP BY
    CONCAT(s.s_store_name, ' (', s.s_city, ')'),
    fi.i_category,
    fi.short_desc,
    CASE
        WHEN regexp_like(fi.i_item_desc, '(?i)^Chocolate') THEN 'CHOCOLATE'
        ELSE 'OTHER'
    END
ORDER BY
    total_net_profit DESC
LIMIT 10
