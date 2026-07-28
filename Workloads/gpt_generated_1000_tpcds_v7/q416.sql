/* Goal: Compare total net loss from store returns and catalog returns by household demographic and item category. */
WITH store_returns_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'store' AS source_type
    FROM store_returns sr
    INNER JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_reversed_charge > 1.0
    GROUP BY hd.hd_demo_sk, i.i_category
),
catalog_returns_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        'catalog' AS source_type
    FROM catalog_returns cr
    INNER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_tax > 5.0
    GROUP BY hd.hd_demo_sk, i.i_category
)
SELECT demo_sk,
       category,
       total_net_loss,
       source_type
FROM (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
) combined
ORDER BY demo_sk,
         category,
         total_net_loss DESC
