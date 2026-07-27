WITH qualified_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_item_desc
    FROM item
    WHERE regexp_like(i_item_desc, '\\bPremium\\w*')
),
store_sales_filtered AS (
    SELECT ss.ss_item_sk,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN qualified_items qi ON ss.ss_item_sk = qi.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_city LIKE 'S%'
      AND cd.cd_dep_college_count >= 2
),
web_sales_filtered AS (
    SELECT ws.ws_item_sk,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN qualified_items qi ON ws.ws_item_sk = qi.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_city LIKE 'S%'
      AND cd.cd_dep_college_count >= 2
      AND wp.wp_url LIKE '%promo%'
),
store_agg AS (
    SELECT ss_item_sk,
           sum(ss_net_profit) AS total_store_profit
    FROM store_sales_filtered
    GROUP BY ss_item_sk
),
web_agg AS (
    SELECT ws_item_sk,
           sum(ws_net_profit) AS total_web_profit
    FROM web_sales_filtered
    GROUP BY ws_item_sk
)
SELECT
    qi.i_category,
    concat('Category: ', qi.i_category) AS category_label,
    max(regexp_extract(qi.i_item_desc, '(Premium\\w*)', 1)) AS premium_word,
    sum(coalesce(sa.total_store_profit, 0) + coalesce(wa.total_web_profit, 0)) AS total_net_profit,
    count(DISTINCT qi.i_item_id) AS distinct_items_sold,
    avg(coalesce(sa.total_store_profit, 0) + coalesce(wa.total_web_profit, 0)) AS avg_net_profit_per_sale,
    (SELECT count(*) FROM warehouse WHERE w_state = 'CA') AS ca_warehouse_cnt
FROM qualified_items qi
LEFT JOIN store_agg sa ON qi.i_item_sk = sa.ss_item_sk
LEFT JOIN web_agg wa ON qi.i_item_sk = wa.ws_item_sk
GROUP BY qi.i_category
HAVING sum(coalesce(sa.total_store_profit, 0) + coalesce(wa.total_web_profit, 0)) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
