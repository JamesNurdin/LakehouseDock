WITH sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_paid) AS total_paid,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year = 2001
    GROUP BY d.d_date, i.i_item_id
)

SELECT DISTINCT
    src.event_date,
    src.item_id,
    src.amount,
    src.source,
    (SELECT AVG(total_paid) FROM sales_agg) AS avg_sales_paid
FROM (
    SELECT
        sa.sale_date AS event_date,
        sa.item_id,
        sa.total_paid AS amount,
        'store_sales' AS source
    FROM sales_agg sa

    UNION ALL

    SELECT
        d.d_date AS event_date,
        i.i_item_id AS item_id,
        SUM(wr.wr_return_amt) AS amount,
        'web_returns' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND d.d_year = 2001
    GROUP BY d.d_date, i.i_item_id
) AS src
ORDER BY src.event_date DESC, src.amount DESC
LIMIT 100
