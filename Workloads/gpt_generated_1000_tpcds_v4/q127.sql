/*
Goal: Calculate profit tiers per call center and item category for 2020 sales of items whose description contains "USB" or "Adapter". The query enriches the result with string‑derived fields, includes return amounts, filters call centers with "Center" in their name, and limits the output to the top 100 rows.
*/
WITH distinct_cc AS (
    SELECT DISTINCT
        cc_call_center_sk,
        cc_name
    FROM call_center
    WHERE regexp_like(cc_name, '(?i)center')
),
sales_agg AS (
    SELECT
        d.d_year,
        dc.cc_call_center_sk,
        dc.cc_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)(USB|Adapter)') AS extracted_term,
        CONCAT(SUBSTRING(dc.cc_name, 1, 5), '-', i.i_category) AS center_category_key
    FROM catalog_sales cs
    JOIN distinct_cc dc ON cs.cs_call_center_sk = dc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(i.i_item_desc, '(?i)usb|adapter')
    GROUP BY
        d.d_year,
        dc.cc_call_center_sk,
        dc.cc_name,
        i.i_category,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)(USB|Adapter)'),
        CONCAT(SUBSTRING(dc.cc_name, 1, 5), '-', i.i_category)
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cr.cr_call_center_sk, i.i_category
)
SELECT
    sa.cc_name,
    sa.i_category,
    sa.total_net_profit,
    sa.total_sales,
    ra.total_return_amount,
    CASE
        WHEN sa.total_net_profit > 100000 THEN 'HIGH'
        WHEN sa.total_net_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_tier,
    sa.extracted_term,
    sa.center_category_key
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.cc_call_center_sk = ra.cr_call_center_sk
   AND sa.i_category = ra.i_category
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = sa.cc_call_center_sk
          AND cs2.cs_ext_sales_price > 10000
        LIMIT 1
    )
  AND sa.cc_name LIKE '%Center%'
ORDER BY sa.total_net_profit DESC
LIMIT 100
