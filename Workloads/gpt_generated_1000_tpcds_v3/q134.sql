WITH filtered_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_details,
        regexp_extract(p.p_promo_id, 'A{2}([A-Z]+)A{2}', 1) AS promo_mid_segment
    FROM promotion p
    WHERE regexp_like(p.p_promo_id, '^AAAAA.*A$')
)
SELECT
    fp.p_promo_id,
    fp.promo_mid_segment,
    CONCAT(fp.p_promo_name, ' - ', sm.sm_type) AS promo_ship_desc,
    sm.sm_carrier,
    SUBSTRING(sm.sm_carrier, 1, 3) AS carrier_prefix,
    td.t_hour AS sale_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    CASE WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cr.cr_return_amount) / SUM(cs.cs_net_paid) ELSE NULL END AS return_rate,
    AVG(cs.cs_ext_ship_cost) AS avg_ship_cost
FROM filtered_promos fp
JOIN catalog_sales cs
    ON cs.cs_promo_sk = fp.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
WHERE
    sm.sm_carrier LIKE 'Fed%'
    AND cd.cd_credit_rating LIKE '%Risk%'
    AND cs.cs_coupon_amt > 100
GROUP BY
    fp.p_promo_id,
    fp.promo_mid_segment,
    fp.p_promo_name,
    sm.sm_type,
    sm.sm_carrier,
    td.t_hour
ORDER BY total_sales DESC
LIMIT 100
