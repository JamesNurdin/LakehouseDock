WITH sales_union AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS channel_sk,
           'catalog' AS channel_type,
           cs_quantity AS qty_sold,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_store_sk,
           'store',
           ss_quantity,
           ss_net_paid,
           ss_net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           'web',
           ws_quantity,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
), returns_union AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_call_center_sk AS channel_sk,
           'catalog' AS channel_type,
           cr_return_quantity AS qty_returned,
           cr_net_loss AS net_loss
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_store_sk,
           'store',
           sr_return_quantity,
           sr_net_loss
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_web_page_sk,
           'web',
           wr_return_quantity,
           wr_net_loss
    FROM web_returns
), sales_daily AS (
    SELECT su.date_sk,
           d.d_date,
           su.channel_type,
           su.channel_sk,
           su.item_sk,
           SUM(su.qty_sold) AS total_qty_sold,
           SUM(su.net_paid) AS total_sales_amount,
           SUM(su.net_profit) AS total_profit
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY su.date_sk, d.d_date, su.channel_type, su.channel_sk, su.item_sk
), returns_daily AS (
    SELECT ru.date_sk,
           d.d_date,
           ru.channel_type,
           ru.channel_sk,
           ru.item_sk,
           SUM(ru.qty_returned) AS total_qty_returned,
           SUM(ru.net_loss) AS total_return_loss
    FROM returns_union ru
    JOIN date_dim d ON ru.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ru.date_sk, d.d_date, ru.channel_type, ru.channel_sk, ru.item_sk
), combined AS (
    SELECT COALESCE(s.date_sk, r.date_sk) AS date_sk,
           COALESCE(s.d_date, r.d_date) AS d_date,
           COALESCE(s.channel_type, r.channel_type) AS channel_type,
           COALESCE(s.channel_sk, r.channel_sk) AS channel_sk,
           COALESCE(s.item_sk, r.item_sk) AS item_sk,
           COALESCE(s.total_qty_sold, 0) - COALESCE(r.total_qty_returned, 0) AS net_quantity,
           COALESCE(s.total_sales_amount, 0) - COALESCE(r.total_return_loss, 0) AS net_amount,
           COALESCE(s.total_profit, 0) AS gross_profit,
           (COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit
    FROM sales_daily s
    FULL OUTER JOIN returns_daily r
        ON s.date_sk = r.date_sk
        AND s.channel_type = r.channel_type
        AND s.item_sk = r.item_sk
), ranked AS (
    SELECT c.*,
           SUM(c.net_profit) OVER (PARTITION BY c.channel_type ORDER BY c.d_date
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit,
           ROW_NUMBER() OVER (PARTITION BY c.channel_type ORDER BY c.net_profit DESC) AS profit_rank,
           CASE
               WHEN c.net_profit > 0 THEN 'POSITIVE'
               WHEN c.net_profit < 0 THEN 'NEGATIVE'
               ELSE 'ZERO'
           END AS profit_sign,
           concat('Channel ', c.channel_type, ' on ', CAST(c.d_date AS VARCHAR)) AS label
    FROM combined c
), top_items AS (
    SELECT ch.channel_type,
           ch.item_sk,
           ch.net_quantity,
           ROW_NUMBER() OVER (PARTITION BY ch.channel_type ORDER BY ch.net_quantity DESC) AS rn
    FROM combined ch
    WHERE ch.net_quantity > 0
), final AS (
    SELECT r.d_date,
           r.channel_type,
           r.channel_sk,
           r.net_quantity,
           r.net_amount,
           r.net_profit,
           r.cum_net_profit,
           r.profit_rank,
           r.profit_sign,
           r.label,
           i.i_product_name,
           CASE WHEN ti.rn = 1 THEN 'TOP_ITEM' ELSE NULL END AS top_item_flag
    FROM ranked r
    LEFT JOIN item i ON r.item_sk = i.i_item_sk
    LEFT JOIN (
        SELECT channel_type, item_sk, rn
        FROM top_items
        WHERE rn = 1
    ) ti ON r.channel_type = ti.channel_type AND r.item_sk = ti.item_sk
)
SELECT *
FROM final
WHERE profit_sign = 'POSITIVE'
UNION ALL
SELECT *
FROM final
WHERE profit_sign = 'NEGATIVE' AND net_quantity < 0
