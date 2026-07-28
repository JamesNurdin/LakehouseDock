WITH base AS (
    SELECT
        d_store.d_year            AS d_year,
        i.i_brand                AS i_brand,
        cr.cr_return_amount      AS cr_return_amount,
        sr.sr_return_amt         AS sr_return_amount,
        wr.wr_return_amt         AS wr_return_amount
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_store
        ON cr.cr_returned_date_sk = d_store.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_store_ret
        ON sr.sr_returned_date_sk = d_store_ret.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_web
        ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_promo
        ON p.p_start_date_sk = d_promo.d_date_sk
    WHERE d_store.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
)
SELECT
    d_year,
    i_brand,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amount) AS total_store_return_amount,
    SUM(wr_return_amount) AS total_web_return_amount,
    COUNT(*)               AS return_rows
FROM base
GROUP BY ROLLUP (d_year, i_brand)
ORDER BY d_year ASC, i_brand ASC NULLS LAST
LIMIT 100
