WITH
    agg_store AS (
        SELECT
            sr_store_sk,
            sr_item_sk,
            SUM(sr_return_amt) AS amount,
            SUM(sr_return_quantity) AS qty_cnt
        FROM store_returns
        GROUP BY sr_store_sk, sr_item_sk
    ),
    agg_catalog AS (
        SELECT
            cr_item_sk,
            cr_reason_sk,
            SUM(cr_return_amount) AS amount,
            COUNT(*) AS qty_cnt
        FROM catalog_returns
        GROUP BY cr_item_sk, cr_reason_sk
    ),
    store_dates AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            d.d_date AS closed_date
        FROM store s
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    ),
    website_dates AS (
        SELECT
            w.web_site_sk,
            w.web_name,
            w.web_state,
            d.d_date AS open_date
        FROM web_site w
        JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
    ),
    store_website AS (
        SELECT
            sd.s_store_sk,
            sd.s_store_name,
            sd.s_state,
            wd.web_site_sk,
            wd.web_name,
            wd.web_state,
            sd.closed_date,
            wd.open_date
        FROM store_dates sd
        FULL OUTER JOIN website_dates wd
            ON sd.closed_date = wd.open_date
    ),
    web_page_dates AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            d.d_date AS creation_date
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    ),
    item_ids_from_store AS (
        SELECT DISTINCT i.i_item_sk AS i_id
        FROM agg_store ar
        JOIN item i ON ar.sr_item_sk = i.i_item_sk
        WHERE i.i_current_price > 100
    ),
    item_ids_from_catalog AS (
        SELECT DISTINCT i.i_item_sk AS i_id
        FROM agg_catalog cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE i.i_current_price > 100
    ),
    common_item_ids AS (
        SELECT i_id FROM item_ids_from_store
        INTERSECT
        SELECT i_id FROM item_ids_from_catalog
    )
SELECT
    'store' AS source,
    su.s_store_name AS name,
    i.i_product_name AS product_name,
    r.r_reason_desc AS reason_desc,
    ar.amount,
    ar.qty_cnt,
    d.d_year,
    wp.wp_url
FROM agg_store ar
JOIN store_website su ON ar.sr_store_sk = su.s_store_sk
JOIN item i ON ar.sr_item_sk = i.i_item_sk
JOIN (
        SELECT sr.sr_store_sk, sr.sr_item_sk, sr.sr_reason_sk
        FROM store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_item_sk, sr.sr_reason_sk
    ) srg ON srg.sr_store_sk = ar.sr_store_sk AND srg.sr_item_sk = ar.sr_item_sk
JOIN reason r ON r.r_reason_sk = srg.sr_reason_sk
JOIN date_dim d ON d.d_date = su.closed_date
JOIN web_page_dates wp ON wp.creation_date = su.closed_date
WHERE i.i_current_price > 100
  AND su.s_state = 'CA'
  AND r.r_reason_desc NOT IN ('Damaged', 'Defective')
  AND wp.wp_url LIKE '%.html'
  AND i.i_item_sk IN (SELECT i_id FROM common_item_ids)

UNION DISTINCT

SELECT
    'catalog' AS source,
    ca.ca_address_id AS name,
    i.i_product_name AS product_name,
    r.r_reason_desc AS reason_desc,
    cr.amount,
    cr.qty_cnt,
    d.d_year,
    CAST(NULL AS varchar) AS url
FROM agg_catalog cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN (
        SELECT cr_item_sk, cr_reason_sk,
               MIN(cr_returned_date_sk) AS min_return_date_sk
        FROM catalog_returns
        GROUP BY cr_item_sk, cr_reason_sk
    ) crd ON crd.cr_item_sk = cr.cr_item_sk AND crd.cr_reason_sk = cr.cr_reason_sk
JOIN date_dim d ON d.d_date_sk = crd.min_return_date_sk
JOIN customer_address ca ON ca.ca_address_sk IN (
        SELECT cr_refunded_addr_sk
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = cr.cr_item_sk
    )
WHERE d.d_year BETWEEN 2000 AND 2001
  AND i.i_current_price > 100
  AND r.r_reason_desc NOT IN ('Damaged', 'Defective')
  AND ca.ca_state = 'CA'
  AND i.i_item_sk IN (SELECT i_id FROM common_item_ids)

ORDER BY amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
