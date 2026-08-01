WITH active_promotions AS (
    SELECT p_promo_sk, p_promo_name
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    td.t_hour AS hour,
    td.t_am_pm AS am_pm,
    ap.p_promo_name AS promo_name,
    cd.cd_gender AS gender,
    'sales' AS source_type,
    SUM(ss.ss_net_paid) AS metric,
    SUM(ss.ss_quantity) AS quantity
FROM store_sales ss
INNER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN active_promotions ap
    ON ss.ss_promo_sk = ap.p_promo_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE td.t_am_pm = 'AM'
    AND cd.cd_gender = 'F'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    td.t_hour,
    td.t_am_pm,
    ap.p_promo_name,
    cd.cd_gender
HAVING SUM(ss.ss_net_paid) > 5000

UNION ALL

SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    td.t_hour AS hour,
    td.t_am_pm AS am_pm,
    p.p_promo_name AS promo_name,
    cd.cd_gender AS gender,
    'returns' AS source_type,
    SUM(sr.sr_net_loss) AS metric,
    SUM(sr.sr_return_quantity) AS quantity
FROM store_returns sr
INNER JOIN store_sales ss
    ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
INNER JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
INNER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
INNER JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE td.t_am_pm = 'PM'
    AND p.p_discount_active = 'N'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    td.t_hour,
    td.t_am_pm,
    p.p_promo_name,
    cd.cd_gender
HAVING SUM(sr.sr_net_loss) > 1000

ORDER BY metric DESC, store_name ASC
LIMIT 100
