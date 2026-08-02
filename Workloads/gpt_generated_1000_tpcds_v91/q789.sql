WITH reason_words AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        word
    FROM reason r
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
    WHERE regexp_like(word, '^[A-Z][a-z]+$')
),

filtered_ship_modes AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_code,
        sm.sm_contract
    FROM ship_mode sm
    WHERE sm.sm_contract LIKE '%h%J%'
),

avg_ship_mode_loss AS (
    SELECT
        cr_ship_mode_sk,
        avg(cr_net_loss) AS avg_net_loss
    FROM catalog_returns
    GROUP BY cr_ship_mode_sk
),

returns_detail AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_refunded_cdemo_sk,
        r.r_reason_desc,
        rwd.word
    FROM catalog_returns cr
    JOIN filtered_ship_modes fsm ON cr.cr_ship_mode_sk = fsm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN reason_words rwd ON r.r_reason_sk = rwd.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '.*[0-9]{4}.*')
      AND rwd.word LIKE 'A%'
)
(
SELECT
    CONCAT('ShipMode_', fsm.sm_ship_mode_id) AS ship_mode_label,
    fsm.sm_ship_mode_id,
    fsm.sm_carrier,
    substring(fsm.sm_code, 1, 2) AS sm_code_prefix,
    COUNT(DISTINCT rd.cr_order_number) AS num_returns,
    SUM(rd.cr_net_loss) AS total_net_loss,
    SUM(ss.ss_net_paid) AS total_sales_paid,
    asl.avg_net_loss AS avg_net_loss_per_ship_mode,
    ARRAY_AGG(DISTINCT rd.word) AS matched_reason_words
FROM returns_detail rd
JOIN filtered_ship_modes fsm ON rd.cr_ship_mode_sk = fsm.sm_ship_mode_sk
JOIN time_dim td ON rd.cr_returned_time_sk = td.t_time_sk
JOIN customer_demographics cd ON rd.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
   AND ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN avg_ship_mode_loss asl ON rd.cr_ship_mode_sk = asl.cr_ship_mode_sk
WHERE td.t_meal_time = 'lunch'
  AND td.t_shift = 'first'
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd_sub
        WHERE cd_sub.cd_demo_sk = rd.cr_refunded_cdemo_sk
          AND cd_sub.cd_dep_count >= 2
          AND cd_sub.cd_gender = 'M'
    )
GROUP BY
    fsm.sm_ship_mode_id,
    fsm.sm_carrier,
    substring(fsm.sm_code, 1, 2),
    asl.avg_net_loss
HAVING SUM(rd.cr_net_loss) > 1000
)
INTERSECT
(
SELECT
    CONCAT('ShipMode_', fsm2.sm_ship_mode_id) AS ship_mode_label,
    fsm2.sm_ship_mode_id,
    fsm2.sm_carrier,
    substring(fsm2.sm_code, 1, 2) AS sm_code_prefix,
    COUNT(DISTINCT rd2.cr_order_number) AS num_returns,
    SUM(rd2.cr_net_loss) AS total_net_loss,
    SUM(ss2.ss_net_paid) AS total_sales_paid,
    asl2.avg_net_loss AS avg_net_loss_per_ship_mode,
    ARRAY_AGG(DISTINCT rd2.word) AS matched_reason_words
FROM returns_detail rd2
JOIN filtered_ship_modes fsm2 ON rd2.cr_ship_mode_sk = fsm2.sm_ship_mode_sk
JOIN time_dim td2 ON rd2.cr_returned_time_sk = td2.t_time_sk
JOIN customer_demographics cd2 ON rd2.cr_refunded_cdemo_sk = cd2.cd_demo_sk
JOIN store_sales ss2
    ON ss2.ss_sold_time_sk = td2.t_time_sk
   AND ss2.ss_cdemo_sk = cd2.cd_demo_sk
JOIN avg_ship_mode_loss asl2 ON rd2.cr_ship_mode_sk = asl2.cr_ship_mode_sk
WHERE td2.t_meal_time = 'dinner'
  AND td2.t_shift = 'second'
  AND regexp_like(rd2.r_reason_desc, '^.*(refund|return).*$')
GROUP BY
    fsm2.sm_ship_mode_id,
    fsm2.sm_carrier,
    substring(fsm2.sm_code, 1, 2),
    asl2.avg_net_loss
)
LIMIT 100
