/*
  Goal: Analyze catalog return net loss by reason and ship mode for morning‑shift returns where the reason ID matches a specific pattern and the refunded customer gender starts with ‘M’, including string extraction, pattern matching, conditional loss categorisation and comparison to average loss per ship‑mode type.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_reversed_charge,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_store_credit,
        r.r_reason_desc,
        r.r_reason_id,
        sm.sm_type,
        sm.sm_carrier,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        t.t_shift,
        t.t_meal_time
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_id, '^AAAAAAA[AB]')               -- pattern on reason ID
      AND cd_ref.cd_gender LIKE 'M%'                               -- gender starts with M
      AND t.t_shift = 'AM'                                         -- only morning shift returns
)
SELECT
    fr.r_reason_desc,
    fr.sm_type,
    fr.t_shift,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_fee) AS avg_fee,
    CASE
        WHEN SUM(fr.cr_net_loss) > 1000 THEN 'High'
        WHEN SUM(fr.cr_net_loss) > 0   THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    (SELECT AVG(cr3.cr_net_loss)
     FROM catalog_returns cr3
     JOIN ship_mode sm3 ON cr3.cr_ship_mode_sk = sm3.sm_ship_mode_sk
     WHERE sm3.sm_type = fr.sm_type) AS avg_net_loss_by_ship_type,
    regexp_extract(fr.r_reason_desc, '(\\w+)') AS first_word_reason,
    MIN(concat(fr.r_reason_id, '-', fr.sm_type)) AS reason_ship_key
FROM filtered_returns fr
GROUP BY
    fr.r_reason_desc,
    fr.sm_type,
    fr.t_shift,
    regexp_extract(fr.r_reason_desc, '(\\w+)')
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC
LIMIT 20
