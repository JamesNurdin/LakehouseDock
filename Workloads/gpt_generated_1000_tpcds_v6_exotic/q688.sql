WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_bill_customer_sk,
        cs.cs_coupon_amt
    FROM catalog_sales cs
    WHERE cs.cs_coupon_amt > 0
)
SELECT
    CASE WHEN GROUPING(i.i_category) = 0 THEN i.i_category ELSE 'ALL CATEGORIES' END AS category,
    CASE WHEN GROUPING(cc.cc_name) = 0 THEN cc.cc_name ELSE 'ALL CALL CENTERS' END AS call_center_name,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    MIN(CONCAT(i.i_brand, ' - ', i.i_item_id)) AS brand_item_example,
    MIN(REGEXP_EXTRACT(i.i_item_desc, '^([A-Za-z]+)', 1)) AS first_word_desc
FROM filtered_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
WHERE
    cc.cc_name LIKE '%Center%'
    AND REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
    AND cs.cs_item_sk IN (
        SELECT cs2.cs_item_sk
        FROM catalog_sales cs2
        GROUP BY cs2.cs_item_sk
        HAVING AVG(cs2.cs_coupon_amt) > 100
    )
GROUP BY GROUPING SETS (
    (i.i_category, cc.cc_name),
    (i.i_category),
    (cc.cc_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
