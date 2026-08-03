WITH promo_channels AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_cost,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        ARRAY[ p.p_channel_email, p.p_channel_tv, p.p_channel_dmail ] AS promo_channels
    FROM promotion p
),
agg AS (
    SELECT
        ca.ca_state,
        i.i_category,
        i.i_size,
        inv.inv_quantity_on_hand,
        ss.ss_sold_date_sk,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        channel
    FROM store_sales ss
    RIGHT OUTER JOIN promo_channels pc
        ON ss.ss_promo_sk = pc.p_promo_sk
    LEFT JOIN item i
        ON pc.p_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    CROSS JOIN UNNEST(pc.promo_channels) AS t (channel)
    WHERE i.i_size IN ('small', 'medium', 'large')
      AND pc.p_cost > 500
      AND inv.inv_quantity_on_hand >= 500
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450940
    GROUP BY
        ca.ca_state,
        i.i_category,
        i.i_size,
        inv.inv_quantity_on_hand,
        ss.ss_sold_date_sk,
        channel
)
SELECT
    ca_state,
    i_category,
    i_size,
    inv_quantity_on_hand,
    ss_sold_date_sk,
    total_net_paid,
    distinct_tickets,
    CASE
        WHEN total_net_paid > 10000 THEN 'High'
        WHEN total_net_paid > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_bucket,
    channel,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
