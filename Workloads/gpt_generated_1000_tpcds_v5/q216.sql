WITH sales_hh AS (
    SELECT
        cs.cs_catalog_page_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        SUM(cs.cs_net_profit) AS sum_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid IS NOT NULL
    GROUP BY cs.cs_catalog_page_sk, hd.hd_demo_sk, hd.hd_vehicle_count
)
SELECT
    cp.cp_catalog_page_id,
    regexp_extract(cp.cp_description, '^([A-Za-z]+)', 1) AS first_word,
    sh.hd_vehicle_count,
    sh.sum_net_paid,
    sh.sum_net_profit,
    sh.order_cnt,
    concat(cp.cp_catalog_page_id, '-', regexp_extract(cp.cp_description, '^([A-Za-z]+)', 1)) AS page_key
FROM sales_hh sh
JOIN catalog_page cp
    ON sh.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    regexp_like(cp.cp_description, '(?i)store')
    AND cp.cp_description LIKE '%experience%'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_hdemo_sk = sh.hd_demo_sk
          AND sr.sr_net_loss > 0
    )
ORDER BY sh.sum_net_profit DESC
LIMIT 100
