WITH
    sales_union AS (
        SELECT cs_sold_date_sk AS sold_date_sk,
               cs_item_sk AS item_sk,
               cs_net_profit AS net_profit,
               cs_net_paid AS net_paid,
               cs_quantity AS quantity,
               cs_call_center_sk AS call_center_sk,
               cs_promo_sk AS promo_sk,
               'catalog' AS channel
        FROM catalog_sales
        UNION ALL
        SELECT ss_sold_date_sk,
               ss_item_sk,
               ss_net_profit,
               ss_net_paid,
               ss_quantity,
               NULL,
               ss_promo_sk,
               'store'
        FROM store_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_item_sk,
               ws_net_profit,
               ws_net_paid,
               ws_quantity,
               NULL,
               ws_promo_sk,
               'web'
        FROM web_sales
    ),
    returns_union AS (
        SELECT cr_returned_date_sk AS returned_date_sk,
               cr_item_sk AS item_sk,
               cr_return_quantity AS return_quantity,
               cr_return_amount AS return_amount,
               cr_net_loss AS net_loss,
               cr_call_center_sk AS call_center_sk,
               'catalog' AS channel
        FROM catalog_returns
        UNION ALL
        SELECT sr_returned_date_sk,
               sr_item_sk,
               sr_return_quantity,
               sr_return_amt,
               sr_net_loss,
               NULL,
               'store'
        FROM store_returns
        UNION ALL
        SELECT wr_returned_date_sk,
               wr_item_sk,
               wr_return_quantity,
               wr_return_amt,
               wr_net_loss,
               NULL,
               'web'
        FROM web_returns
    ),
    sales_agg AS (
        SELECT su.channel,
               su.item_sk,
               i.i_item_id AS i_item_id,
               d.d_year,
               SUM(su.net_profit) AS total_net_profit,
               SUM(su.net_paid) AS total_net_paid,
               SUM(su.quantity) AS total_quantity,
               MIN(su.call_center_sk) AS call_center_sk,
               MIN(su.promo_sk) AS promo_sk
        FROM sales_union su
        JOIN item i ON su.item_sk = i.i_item_sk
        JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
        GROUP BY su.channel, su.item_sk, i.i_item_id, d.d_year
    ),
    returns_agg AS (
        SELECT ru.channel,
               ru.item_sk,
               d.d_year,
               SUM(ru.net_loss) AS total_net_loss,
               SUM(ru.return_quantity) AS total_return_qty,
               SUM(ru.return_amount) AS total_return_amount,
               MIN(ru.call_center_sk) AS call_center_sk
        FROM returns_union ru
        JOIN date_dim d ON ru.returned_date_sk = d.d_date_sk
        GROUP BY ru.channel, ru.item_sk, d.d_year
    ),
    combined AS (
        SELECT
            sa.channel,
            sa.d_year,
            sa.item_sk,
            sa.i_item_id,
            sa.total_net_profit,
            COALESCE(ra.total_net_loss, 0) AS total_net_loss,
            (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_adj,
            sa.total_quantity,
            COALESCE(ra.total_return_qty, 0) AS total_return_qty,
            CASE
                WHEN sa.total_quantity = 0 THEN NULL
                ELSE CAST(COALESCE(ra.total_return_qty, 0) AS DOUBLE) / sa.total_quantity
            END AS return_rate,
            ROW_NUMBER() OVER (PARTITION BY sa.channel ORDER BY sa.total_net_profit DESC) AS profit_rank,
            CONCAT(sa.i_item_id, '_', sa.channel) AS item_channel_key,
            COALESCE(cc.cc_name, 'N/A') AS call_center_name,
            CASE
                WHEN sa.total_net_profit > 100000 THEN 'High'
                WHEN sa.total_net_profit > 50000 THEN 'Medium'
                ELSE 'Low'
            END AS profit_tier,
            (SELECT MAX(s2.total_net_profit) FROM sales_agg s2 WHERE s2.item_sk = sa.item_sk) AS max_profit_for_item,
            (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = sa.item_sk) AS store_sales_cnt,
            p.p_promo_name AS promo_name
        FROM sales_agg sa
        LEFT JOIN returns_agg ra
            ON sa.channel = ra.channel
           AND sa.item_sk = ra.item_sk
           AND sa.d_year = ra.d_year
        LEFT JOIN call_center cc
            ON (sa.channel IN ('store','catalog') AND sa.call_center_sk = cc.cc_call_center_sk)
        LEFT JOIN promotion p
            ON sa.promo_sk = p.p_promo_sk
    ),
    high_profit AS (
        SELECT * FROM combined WHERE profit_tier = 'High' AND return_rate < 0.05
    ),
    low_profit AS (
        SELECT * FROM combined WHERE profit_tier = 'Low' AND return_rate > 0.2
    ),
    intersect_items AS (
        SELECT * FROM high_profit
        INTERSECT
        SELECT * FROM low_profit
    ),
    combined_set AS (
        (SELECT * FROM high_profit
         UNION ALL
         SELECT * FROM low_profit)
        EXCEPT
        SELECT * FROM intersect_items
    )
SELECT
    cs.channel,
    cs.d_year,
    cs.i_item_id,
    cs.item_channel_key,
    cs.total_net_profit,
    cs.total_net_loss,
    cs.net_profit_adj,
    cs.total_quantity,
    cs.total_return_qty,
    cs.return_rate,
    cs.profit_rank,
    cs.call_center_name,
    cs.profit_tier,
    cs.max_profit_for_item,
    cs.store_sales_cnt,
    COALESCE(cs.promo_name, 'No Promo') AS promo_name,
    ai.avg_net_profit_all_channels
FROM combined_set cs
JOIN (
    SELECT item_sk, AVG(total_net_profit) AS avg_net_profit_all_channels
    FROM sales_agg
    GROUP BY item_sk
) ai ON cs.item_sk = ai.item_sk
ORDER BY cs.channel, cs.d_year DESC, cs.profit_rank
LIMIT 200
