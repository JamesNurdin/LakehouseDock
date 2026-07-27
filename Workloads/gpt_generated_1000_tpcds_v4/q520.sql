WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_net_loss > 0
),
joined_data AS (
    SELECT
        fr.cr_order_number,
        fr.cr_return_quantity,
        fr.cr_net_loss,
        i.i_product_name,
        i.i_item_desc,
        cp.cp_department,
        cp.cp_catalog_page_number,
        c.c_customer_id,
        cd.cd_credit_rating,
        ca.ca_state,
        CASE WHEN regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$') THEN 1 ELSE 0 END AS has_three_upper,
        substr(i.i_item_desc, 1, 10) AS desc_prefix
    FROM filtered_returns fr
    JOIN catalog_sales cs
        ON fr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON fr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON fr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON fr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type LIKE 'A%'
      AND cd.cd_credit_rating = 'Good'
      AND regexp_extract(i.i_product_name, '(\\d{4})', 1) IS NOT NULL
)
SELECT
    jd.cp_department,
    jd.cp_catalog_page_number,
    COUNT(*) AS return_cnt,
    SUM(jd.cr_net_loss) AS total_net_loss,
    AVG(jd.cr_net_loss) AS avg_net_loss,
    SUM(jd.has_three_upper) AS cnt_three_upper,
    MAX(jd.desc_prefix) AS example_desc_prefix
FROM joined_data jd
WHERE jd.has_three_upper = 1
  AND jd.c_customer_id IN (
        SELECT c2.c_customer_id
        FROM customer c2
        JOIN customer_demographics cd2
            ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
        WHERE cd2.cd_dep_count >= 2
          AND cd2.cd_credit_rating LIKE '%Risk%'
    )
GROUP BY jd.cp_department, jd.cp_catalog_page_number
HAVING SUM(jd.cr_net_loss) > (
        SELECT AVG(cr2.cr_net_loss) * 1.5
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    )
ORDER BY total_net_loss DESC
LIMIT 100
