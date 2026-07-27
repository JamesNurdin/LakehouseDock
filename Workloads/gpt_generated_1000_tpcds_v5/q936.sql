WITH returns_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        cp.cp_department,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        w.web_name,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        CASE
            WHEN cr.cr_return_amount < 50 THEN 'Low'
            WHEN cr.cr_return_amount < 200 THEN 'Medium'
            ELSE 'High'
        END AS return_amount_category,
        (
            SELECT avg(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = cr.cr_item_sk
        ) AS avg_item_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND cd_ref.cd_dep_count >= 2
      AND w.web_mkt_id IN (1, 2, 3)
)
SELECT
    d_year,
    i_category,
    return_amount_category,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(avg_item_return_amount) AS avg_return_amount_per_item
FROM returns_detail
GROUP BY d_year, i_category, return_amount_category
HAVING SUM(cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
