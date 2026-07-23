WITH cs AS (
    SELECT
        cs.cs_item_sk AS i_item_sk,
        cs.cs_call_center_sk,
        cc.cc_name,
        cs.cs_net_paid_inc_ship AS net_amount,
        cs.cs_net_profit AS net_profit,
        i.i_category,
        i.i_category_id,
        i.i_class_id
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '\\d{3}')
      AND cc.cc_name LIKE '%Market%'
),
ss AS (
    SELECT
        ss.ss_item_sk AS i_item_sk,
        NULL AS cs_call_center_sk,
        NULL AS cc_name,
        ss.ss_net_paid AS net_amount,
        ss.ss_net_profit AS net_profit,
        i.i_category,
        i.i_category_id,
        i.i_class_id
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%Special%'
)
SELECT
    COALESCE(t.cc_name, 'Store') AS sales_channel,
    t.i_category,
    t.i_category_id,
    t.i_class_id,
    COUNT(DISTINCT t.i_item_sk) AS distinct_item_count,
    SUM(t.net_amount) AS total_net_amount,
    SUM(t.net_profit) AS total_net_profit,
    CONCAT(SUBSTRING(COALESCE(t.cc_name, ''), 1, 5), ':', t.i_category) AS channel_category_code
FROM (
    SELECT
        i_item_sk,
        cs_call_center_sk,
        cc_name,
        net_amount,
        net_profit,
        i_category,
        i_category_id,
        i_class_id
    FROM cs
    UNION ALL
    SELECT
        i_item_sk,
        cs_call_center_sk,
        cc_name,
        net_amount,
        net_profit,
        i_category,
        i_category_id,
        i_class_id
    FROM ss
) t
GROUP BY
    COALESCE(t.cc_name, 'Store'),
    t.i_category,
    t.i_category_id,
    t.i_class_id,
    CONCAT(SUBSTRING(COALESCE(t.cc_name, ''), 1, 5), ':', t.i_category)
ORDER BY total_net_amount DESC
LIMIT 100
