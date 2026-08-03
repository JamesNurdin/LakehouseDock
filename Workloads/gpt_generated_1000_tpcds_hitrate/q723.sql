WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        REGEXP_EXTRACT(cc.cc_name, '(\\w+)') AS cc_first_word,
        CONCAT('CC_', CAST(cc.cc_call_center_id AS VARCHAR)) AS cc_id_concat,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(cc.cc_name, '(?i)development')
      AND cp.cp_description LIKE '%watch%'
    GROUP BY cs.cs_item_sk, cc.cc_name, cc.cc_call_center_id
),
store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        MAX(t.t_am_pm) AS am_pm_indicator
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 12 AND 23
      AND t.t_am_pm = 'PM'
    GROUP BY ss.ss_item_sk
)
SELECT
    COALESCE(s.item_sk, c.item_sk) AS item_sk,
    s.store_net_profit,
    c.catalog_net_profit,
    c.cc_first_word,
    c.cc_id_concat,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0)) DESC) AS rn
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.item_sk = c.item_sk
WHERE EXISTS (
    SELECT 1 FROM tpcds.store_sales ss2
    WHERE ss2.ss_item_sk = COALESCE(s.item_sk, c.item_sk)
      AND ss2.ss_quantity > 10
)
ORDER BY rn
LIMIT 100
