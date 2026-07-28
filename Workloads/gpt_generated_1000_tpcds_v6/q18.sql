WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_net_loss,
        i.i_category,
        i.i_class,
        i.i_item_desc,
        cp.cp_description,
        wp.wp_url,
        d.d_year
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '(police|legal)')
      AND i.i_category LIKE 'S%'
      AND wp.wp_url LIKE '%promo%'
      AND regexp_like(cp.cp_description, '^.*discount.*$')
)
SELECT
    d.d_year,
    i.i_category,
    concat(i.i_category, '-', i.i_class) AS cat_class,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    MAX(wp.wp_url) AS sample_url
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE regexp_like(i.i_item_desc, '(police|legal)')
  AND i.i_category LIKE 'S%'
  AND wp.wp_url LIKE '%promo%'
  AND regexp_like(cp.cp_description, '^.*discount.*$')
GROUP BY d.d_year, i.i_category, concat(i.i_category, '-', i.i_class)
ORDER BY total_net_loss DESC
LIMIT 100
