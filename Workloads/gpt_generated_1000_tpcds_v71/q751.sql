WITH cat_returns AS (
    SELECT i.i_category AS category,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt,
           'catalog' AS source
    FROM catalog_returns cr
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand_id = 2004002
      AND i.i_class_id = 6
    GROUP BY i.i_category
),
web_returns_cte AS (
    SELECT i.i_category AS category,
           SUM(wr.wr_return_amt) AS total_return_amount,
           COUNT(*) AS return_cnt,
           'web' AS source
    FROM web_returns wr
    INNER JOIN item i ON wr.wr_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand_id = 2004002
      AND cd.cd_dep_employed_count >= 2
    GROUP BY i.i_category
)
SELECT category,
       total_return_amount,
       return_cnt,
       source
FROM cat_returns
UNION ALL
SELECT category,
       total_return_amount,
       return_cnt,
       source
FROM web_returns_cte
ORDER BY total_return_amount DESC
LIMIT 100
