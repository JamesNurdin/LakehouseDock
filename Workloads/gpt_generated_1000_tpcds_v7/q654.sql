WITH cr_base AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    td.t_meal_time,
    r.r_reason_desc,
    SUM(cr_base.cr_return_amount)               AS total_return_amount,
    COUNT(*)                                    AS return_cnt,
    AVG(cr_base.cr_return_quantity)            AS avg_quantity,
    MAX(cr_base.cr_return_amt_inc_tax)         AS max_inc_tax,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM cr_base
JOIN time_dim td
    ON cr_base.cr_returned_time_sk = td.t_time_sk
JOIN item i
    ON cr_base.cr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON cr_base.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cr_base.cr_refunded_addr_sk = ca.ca_address_sk
JOIN reason r
    ON cr_base.cr_reason_sk = r.r_reason_sk
WHERE td.t_meal_time = 'dinner'
  AND ca.ca_state = 'CA'
  AND hd.hd_income_band_sk = 16
  AND p.p_discount_active = 'Y'
GROUP BY i.i_brand, i.i_category, hd.hd_buy_potential, td.t_meal_time, r.r_reason_desc
HAVING SUM(cr_base.cr_return_amount) > (
    SELECT AVG(cr_return_amount) FROM catalog_returns
)
ORDER BY total_return_amount DESC
