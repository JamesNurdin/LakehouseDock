WITH mail_promos AS (
    SELECT
        i.i_brand,
        'dmail' AS channel,
        AVG(p.p_cost) AS avg_cost,
        COUNT(*) AS promo_cnt
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_channel_dmail = 'Y'
      AND i.i_formulation LIKE '%moccasin%'
      AND i.i_rec_end_date > DATE '2000-01-01'
    GROUP BY i.i_brand
),
email_promos AS (
    SELECT
        i.i_brand,
        'email' AS channel,
        AVG(p.p_cost) AS avg_cost,
        COUNT(*) AS promo_cnt
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_channel_email = 'Y'
      AND i.i_formulation LIKE '%blue%'
      AND i.i_rec_end_date > DATE '2000-01-01'
    GROUP BY i.i_brand
)
SELECT i_brand, channel, avg_cost, promo_cnt
FROM mail_promos
UNION ALL
SELECT i_brand, channel, avg_cost, promo_cnt
FROM email_promos
ORDER BY i_brand, channel
