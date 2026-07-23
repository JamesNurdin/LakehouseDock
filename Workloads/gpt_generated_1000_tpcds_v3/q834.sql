WITH store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        'store' AS channel,
        CAST(NULL AS varchar) AS call_center_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
              AND sr.sr_returned_date_sk = d.d_date_sk
        ) AS returns_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND d.d_current_month = 'Y'
      AND t.t_am_pm = 'PM'
    GROUP BY i.i_item_id, i.i_item_sk, d.d_date_sk, p.p_discount_active
),
catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        'catalog' AS channel,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_transactions,
        COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
        (
            SELECT COUNT(*)
            FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
              AND wr.wr_returned_date_sk = d.d_date_sk
        ) AS returns_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND d.d_current_month = 'Y'
      AND t.t_am_pm = 'PM'
    GROUP BY i.i_item_id, i.i_item_sk, d.d_date_sk, p.p_discount_active, cc.cc_name
),
combined AS (
    SELECT item_id, channel, call_center_name, total_sales, total_profit, num_transactions, promo_active_flag, returns_count
    FROM store_agg
    UNION ALL
    SELECT item_id, channel, call_center_name, total_sales, total_profit, num_transactions, promo_active_flag, returns_count
    FROM catalog_agg
)
SELECT
    item_id,
    channel,
    call_center_name,
    total_sales,
    total_profit,
    num_transactions,
    promo_active_flag,
    returns_count,
    ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_sales DESC) AS sales_rank
FROM combined
ORDER BY total_sales DESC, item_id
LIMIT 100
