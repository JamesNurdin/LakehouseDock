WITH promo_channels AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            p.p_discount_active,
            channel
        FROM promotion p
        CROSS JOIN UNNEST(ARRAY[p.p_channel_dmail, p.p_channel_email, p.p_channel_catalog]) AS t(channel)
        WHERE p.p_discount_active = 'Y'
    ),
    catalog_sub AS (
        SELECT
            cs.cs_order_number                AS order_key,
            i.i_item_sk,
            i.i_item_id,
            cs.cs_net_profit                 AS net_profit,
            r.r_reason_desc                  AS reason_desc,
            pc.channel,
            'catalog'                        AS src,
            cs.cs_sold_time_sk               AS time_sk
        FROM catalog_sales cs
        JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN promo_channels pc
            ON cs.cs_promo_sk = pc.p_promo_sk
        WHERE cs.cs_sold_time_sk BETWEEN 1 AND 86400
    ),
    store_sub AS (
        SELECT
            ss.ss_ticket_number               AS order_key,
            i.i_item_sk,
            i.i_item_id,
            ss.ss_net_profit                 AS net_profit,
            r.r_reason_desc                  AS reason_desc,
            pc.channel,
            'store'                          AS src,
            ss.ss_sold_time_sk               AS time_sk
        FROM store_sales ss
        JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        LEFT JOIN promo_channels pc
            ON ss.ss_promo_sk = pc.p_promo_sk
        WHERE ss.ss_sold_time_sk BETWEEN 1 AND 86400
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS rn,
    src,
    order_key,
    i_item_id,
    net_profit,
    reason_desc,
    CASE WHEN channel IS NULL THEN 'NoActiveChannel' ELSE channel END AS active_channel
FROM (
    SELECT * FROM catalog_sub
    UNION ALL
    SELECT * FROM store_sub
) u
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = u.i_item_sk
      AND p.p_discount_active = 'Y'
)
ORDER BY rn
LIMIT 100
