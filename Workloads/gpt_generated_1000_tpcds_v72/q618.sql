WITH
    filtered_items AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            regexp_extract(i.i_product_name, '(?i)(Premium|Deluxe)', 1) AS product_tag,
            i.i_current_price
        FROM item i
        WHERE regexp_like(i.i_product_name, '(?i)Premium|Deluxe')
    )
SELECT
    sales.site_id,
    sales.product_tag,
    sales.amount,
    sales.metric,
    sales.max_return_amount
FROM (
    SELECT
        ws_site.web_site_id AS site_id,
        fi.product_tag,
        SUM(ws.ws_net_paid) AS amount,
        'sales' AS metric,
        (
            SELECT MAX(cr2.cr_return_amount)
            FROM catalog_returns cr2
            JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
            WHERE i2.i_product_name LIKE CONCAT('%', fi.product_tag, '%')
        ) AS max_return_amount
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE cd.cd_purchase_estimate > 5000
      AND ws_site.web_tax_percentage > 0.09
      AND ws_site.web_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = ws.ws_item_sk
              AND cr.cr_returned_date_sk = ws.ws_sold_date_sk
        )
    GROUP BY ws_site.web_site_id, fi.product_tag
) AS sales
UNION ALL
SELECT
    NULL AS site_id,
    fi.product_tag,
    SUM(cr.cr_return_amount) AS amount,
    'returns' AS metric,
    NULL AS max_return_amount
FROM catalog_returns cr
JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
WHERE fi.product_tag LIKE '%Premium%'
GROUP BY fi.product_tag
ORDER BY amount DESC, site_id NULLS LAST, metric
LIMIT 100
