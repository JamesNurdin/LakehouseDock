WITH joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        p1.p_promo_id        AS promo_id_item,
        p2.p_promo_id        AS promo_id_sale,
        p3.p_promo_name      AS promo_name_item,
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws_site.web_name,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax
    FROM item i
    JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk                                    -- join 1
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk                 -- join 2
    JOIN promotion p1
        ON i.i_item_sk = p1.p_item_sk                                    -- join 3 (first promo alias)
    JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk                                    -- join 4
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk                         -- join 5
    JOIN promotion p2
        ON ws.ws_promo_sk = p2.p_promo_sk                                 -- join 6 (second promo alias)
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number                       -- join 7
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk                                    -- join 8
    JOIN promotion p3
        ON i.i_item_sk = p3.p_item_sk                                    -- join 9 (third promo alias)
),
agg_data AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        cp_catalog_number,
        promo_id_item,
        promo_id_sale,
        promo_name_item,
        web_name,
        SUM(cr_return_amount + sr_return_amt + wr_return_amt) AS total_return_amount,
        CASE
            WHEN SUM(cr_return_amount + sr_return_amt + wr_return_amt) > 1000 THEN 'HIGH'
            ELSE 'LOW'
        END AS return_category
    FROM joined_data
    GROUP BY
        i_item_sk,
        i_item_id,
        i_product_name,
        cp_catalog_number,
        promo_id_item,
        promo_id_sale,
        promo_name_item,
        web_name
)
SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    cp_catalog_number,
    promo_id_item,
    promo_id_sale,
    promo_name_item,
    web_name,
    total_return_amount,
    return_category,
    rn
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY total_return_amount DESC) AS rn
    FROM agg_data
) t
WHERE rn <= 3
ORDER BY total_return_amount DESC
LIMIT 100
