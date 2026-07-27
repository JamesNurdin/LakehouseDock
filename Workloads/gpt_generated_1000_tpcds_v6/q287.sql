WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i.i_brand,
        i.i_product_name,
        i.i_container,
        i.i_brand_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_name
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{2}')
      AND i.i_container LIKE '%Box%'
      AND i.i_brand_id IN (3003001, 5002002)
)
SELECT
    concat_ws(' - ', fr.i_brand, substring(fr.i_product_name, 1, 15)) AS product_label,
    fr.w_warehouse_name,
    fr.ib_lower_bound,
    fr.ib_upper_bound,
    sum(fr.cr_return_amount) AS total_return_amount,
    sum(fr.cr_return_quantity) AS total_return_qty,
    count(*) AS num_returns
FROM filtered_returns fr
GROUP BY
    concat_ws(' - ', fr.i_brand, substring(fr.i_product_name, 1, 15)),
    fr.w_warehouse_name,
    fr.ib_lower_bound,
    fr.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
