WITH agg_cr AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee > 10
    GROUP BY cr.cr_item_sk, cr.cr_reason_sk, cr.cr_catalog_page_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS store_return_amount,
    agg.total_return_amount,
    SUM(sr.sr_return_quantity) AS store_return_qty,
    agg.total_return_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(sr.sr_return_amt) DESC) AS store_return_rank,
    CASE
        WHEN agg.total_return_amount > 1000 THEN 'High Catalog Returns'
        ELSE 'Low Catalog Returns'
    END AS catalog_return_category
FROM agg_cr agg
JOIN item i ON i.i_item_sk = agg.cr_item_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = agg.cr_catalog_page_sk
JOIN reason r ON r.r_reason_sk = agg.cr_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td ON td.t_time_sk = sr.sr_return_time_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
WHERE i.i_category_id IN (1, 2, 5)
  AND cd.cd_education_status = 'Advanced Degree'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    r.r_reason_desc,
    agg.total_return_amount,
    agg.total_return_qty,
    CASE
        WHEN agg.total_return_amount > 1000 THEN 'High Catalog Returns'
        ELSE 'Low Catalog Returns'
    END
HAVING SUM(sr.sr_return_amt) > 500
ORDER BY store_return_amount DESC, i.i_item_id
LIMIT 100
