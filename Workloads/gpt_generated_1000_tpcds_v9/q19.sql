WITH base_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returned_time_sk
    FROM catalog_returns cr
),
refunded_returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        SUM(br.cr_return_amount) AS total_return_amount,
        AVG(br.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN regexp_like(i.i_product_name, '(?i)bar') THEN 'ContainsBar' ELSE 'Other' END AS product_name_flag,
        substr(td.t_time_id, 1, 8) AS time_prefix,
        concat(i.i_item_id, '-', CAST(td.t_hour AS VARCHAR)) AS item_hour_key,
        regexp_extract(i.i_item_id, '([A-Z]{3})', 1) AS item_prefix,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM base_returns br
    INNER JOIN item i ON br.cr_item_sk = i.i_item_sk
    INNER JOIN time_dim td ON br.cr_returned_time_sk = td.t_time_sk
    INNER JOIN household_demographics hd ON br.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE ib.ib_lower_bound >= 30000
      AND ib.ib_upper_bound <= 50000
      AND regexp_like(i.i_product_name, '(?i)bar')
      AND td.t_shift LIKE 'second%'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        CASE WHEN regexp_like(i.i_product_name, '(?i)bar') THEN 'ContainsBar' ELSE 'Other' END,
        substr(td.t_time_id, 1, 8),
        concat(i.i_item_id, '-', CAST(td.t_hour AS VARCHAR)),
        regexp_extract(i.i_item_id, '([A-Z]{3})', 1)
),
returning_household_returns AS (
    SELECT
        hd.hd_buy_potential,
        COUNT(*) AS cnt_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN hd.hd_buy_potential LIKE 'High%' THEN 'HighPotential' ELSE 'OtherPotential' END AS buy_potential_flag,
        MAX(cr.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    INNER JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential LIKE 'High%'
    GROUP BY
        hd.hd_buy_potential,
        CASE WHEN hd.hd_buy_potential LIKE 'High%' THEN 'HighPotential' ELSE 'OtherPotential' END
)
SELECT DISTINCT
    rr.i_item_id,
    rr.i_product_name,
    rr.i_category,
    rr.total_return_amount,
    rr.avg_return_amount,
    rr.return_cnt,
    rr.product_name_flag,
    rr.time_prefix,
    rr.item_hour_key,
    rr.item_prefix,
    rr.total_quantity_on_hand
FROM refunded_returns rr
UNION ALL
SELECT
    NULL AS i_item_id,
    NULL AS i_product_name,
    NULL AS i_category,
    rh.total_return_amount,
    NULL AS avg_return_amount,
    rh.cnt_returns AS return_cnt,
    rh.buy_potential_flag,
    NULL AS time_prefix,
    NULL AS item_hour_key,
    NULL AS item_prefix,
    NULL AS total_quantity_on_hand
FROM returning_household_returns rh
ORDER BY total_return_amount DESC
LIMIT 100
