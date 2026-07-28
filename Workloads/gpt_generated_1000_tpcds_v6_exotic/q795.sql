/* goal: Identify the top product categories and brands with the highest total return amount for returns whose reason mentions damage or breakage, where the product name contains the word 'Premium' and the item has been sold from warehouses in Michigan. The query demonstrates regex filtering, string extraction, concatenation, a CTE, an EXISTS sub‑query, aggregation, a window function, ordering and a LIMIT. */
WITH filtered_returns AS (
    SELECT
        sr.sr_item_sk,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        r.r_reason_desc,
        sr.sr_return_amt,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damaged|broken')
      AND i.i_product_name LIKE '%Premium%'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
          WHERE cs.cs_item_sk = sr.sr_item_sk
            AND w.w_state = 'MI'
      )
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        first_word,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM filtered_returns
    GROUP BY i_category, i_brand, first_word
)
SELECT
    a.i_category,
    a.i_brand,
    CONCAT(a.i_brand, ' - ', a.first_word) AS brand_first_word,
    a.total_return_amount,
    a.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_return_amount DESC) AS rn
FROM aggregated a
WHERE a.total_return_amount > 0
ORDER BY a.total_return_amount DESC
LIMIT 100
