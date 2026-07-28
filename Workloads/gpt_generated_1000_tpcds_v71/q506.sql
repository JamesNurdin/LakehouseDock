WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        i.i_manufact,
        i.i_item_desc,
        i.i_current_price,
        sm.sm_carrier,
        p.p_promo_name,
        p.p_channel_details
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{2,}')
      AND i.i_manufact LIKE '%e%'
      AND NOT EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
            AND sm2.sm_carrier LIKE '%XYZ%'
      )
),
agg AS (
    SELECT
        r.i_manufact,
        r.i_item_desc,
        r.p_promo_name,
        COUNT(*) AS return_cnt,
        SUM(r.cr_return_amount) AS total_return_amount,
        AVG(r.cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN r.cr_return_amount > 100 THEN r.cr_return_amount ELSE 0 END) AS high_value_returns,
        REGEXP_EXTRACT(r.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
        CONCAT(r.i_manufact, ' - ', r.p_promo_name) AS manufact_promo
    FROM filtered_returns r
    GROUP BY r.i_manufact, r.i_item_desc, r.p_promo_name
)
SELECT
    a.i_manufact,
    a.i_item_desc,
    a.p_promo_name,
    a.return_cnt,
    a.total_return_amount,
    a.avg_return_amount,
    a.high_value_returns,
    a.first_number_in_desc,
    a.manufact_promo,
    SUM(a.total_return_amount) OVER (PARTITION BY a.i_manufact) AS total_per_manufact,
    ROW_NUMBER() OVER (PARTITION BY a.i_manufact ORDER BY a.total_return_amount DESC) AS rn
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
