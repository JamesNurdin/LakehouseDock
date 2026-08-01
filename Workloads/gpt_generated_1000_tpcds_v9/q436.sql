WITH filtered_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT item_sk,
       source,
       net_profit,
       total_quantity,
       promo_count,
       total_return_qty
FROM (
    SELECT
        cs.cs_item_sk AS item_sk,
        'catalog' AS source,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_promo_sk) AS promo_count,
        COALESCE((
            SELECT SUM(sr.sr_return_quantity)
            FROM store_returns sr
            JOIN store_sales ss2
                ON sr.sr_item_sk = ss2.ss_item_sk
               AND sr.sr_ticket_number = ss2.ss_ticket_number
            WHERE ss2.ss_item_sk = cs.cs_item_sk
        ), 0) AS total_return_qty
    FROM catalog_sales cs
    JOIN filtered_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
    GROUP BY cs.cs_item_sk

    UNION ALL

    SELECT
        ss.ss_item_sk AS item_sk,
        'store' AS source,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_promo_sk) AS promo_count,
        COALESCE((
            SELECT SUM(sr.sr_return_quantity)
            FROM store_returns sr
            JOIN store_sales ss2
                ON sr.sr_item_sk = ss2.ss_item_sk
               AND sr.sr_ticket_number = ss2.ss_ticket_number
            WHERE ss2.ss_item_sk = ss.ss_item_sk
        ), 0) AS total_return_qty
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
    GROUP BY ss.ss_item_sk
) AS combined
ORDER BY net_profit DESC
LIMIT 100
