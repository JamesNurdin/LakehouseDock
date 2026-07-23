WITH catalog_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        concat(i.i_brand, '-', i.i_category) AS brand_category,
        substring(i.i_item_desc FROM 1 FOR 5) AS desc_prefix,
        sum(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE
        regexp_like(i.i_item_desc, '(?i)large')
        AND i.i_item_desc LIKE '%large%'
    GROUP BY
        d.d_year,
        d.d_moy,
        concat(i.i_brand, '-', i.i_category),
        substring(i.i_item_desc FROM 1 FOR 5)
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        concat(i.i_brand, '-', i.i_category) AS brand_category,
        regexp_extract(wp.wp_url, '/p([0-9]{4,})/', 1) AS url_product_id,
        sum(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        regexp_like(wp.wp_url, '/p[0-9]{4,}/')
        AND wp.wp_url LIKE '%/p%'
    GROUP BY
        d.d_year,
        d.d_moy,
        concat(i.i_brand, '-', i.i_category),
        regexp_extract(wp.wp_url, '/p([0-9]{4,})/', 1)
)
SELECT
    coalesce(c.d_year, w.d_year) AS year,
    coalesce(c.d_moy, w.d_moy) AS month,
    coalesce(c.brand_category, w.brand_category) AS brand_category,
    c.desc_prefix,
    w.url_product_id,
    c.catalog_net_loss,
    w.web_net_loss,
    (coalesce(c.catalog_net_loss, 0) + coalesce(w.web_net_loss, 0)) AS total_net_loss
FROM catalog_agg c
FULL OUTER JOIN web_agg w
    ON c.d_year = w.d_year
    AND c.d_moy = w.d_moy
    AND c.brand_category = w.brand_category
ORDER BY total_net_loss DESC
LIMIT 100
