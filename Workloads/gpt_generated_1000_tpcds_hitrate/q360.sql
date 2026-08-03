WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        d.d_quarter_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_quarter_name
)
SELECT
    COALESCE(cc.cc_name, 'UNKNOWN_CALL_CENTER') AS call_center_name,
    COALESCE(d.d_quarter_name, 'UNKNOWN_QUARTER') AS quarter,
    i.i_product_name,
    i.i_category,
    s.total_net_paid,
    s.sales_cnt,
    SUBSTR(i.i_product_name, 1, POSITION(' ' IN i.i_product_name) - 1) AS product_first_word,
    CONCAT(cc.cc_name, ' - ', d.d_quarter_name) AS cc_quarter_label,
    CASE WHEN REGEXP_LIKE(i.i_product_name, '(?i)bike|chair') THEN 'Matched' ELSE 'Other' END AS product_match_flag,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS category_avg_price
FROM call_center cc
FULL OUTER JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN sales_agg s
    ON s.d_quarter_name = d.d_quarter_name
LEFT JOIN item i
    ON s.cs_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
      AND REGEXP_LIKE(p.p_promo_name, '^Summer')
)
  AND (REGEXP_LIKE(i.i_product_name, '^[A-Za-z]+[0-9]{3}$') OR i.i_product_name LIKE '%Free%')
ORDER BY s.total_net_paid DESC
LIMIT 100
