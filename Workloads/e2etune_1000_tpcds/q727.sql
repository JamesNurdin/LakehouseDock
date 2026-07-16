WITH store_agg AS (
    SELECT
        p.p_promo_name,
        d.d_moy AS month,
        d.d_holiday AS holiday_flag,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
      AND d.d_quarter_seq = 2
      AND d.d_weekend = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, d.d_moy, d.d_holiday
),
web_agg AS (
    SELECT
        p.p_promo_name,
        d.d_moy AS month,
        d.d_holiday AS holiday_flag,
        wp.wp_type AS page_type,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_quarter_seq = 2
      AND d.d_weekend = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, d.d_moy, d.d_holiday, wp.wp_type
)
SELECT
    COALESCE(sa.p_promo_name, wa.p_promo_name) AS promo_name,
    COALESCE(sa.month, wa.month) AS month,
    COALESCE(sa.holiday_flag, wa.holiday_flag) AS holiday_flag,
    COALESCE(wa.page_type, 'STORE') AS channel_or_page_type,
    COALESCE(sa.store_net_profit, 0) AS store_net_profit,
    COALESCE(wa.web_net_profit, 0) AS web_net_profit,
    COALESCE(wa.returns_net_loss, 0) AS returns_net_loss,
    COALESCE(sa.store_net_paid_inc_tax, 0) AS store_net_paid_inc_tax,
    COALESCE(wa.web_net_paid_inc_tax, 0) AS web_net_paid_inc_tax,
    CASE
        WHEN COALESCE(sa.store_net_profit, 0) = 0 THEN NULL
        ELSE (COALESCE(wa.web_net_profit, 0) - COALESCE(wa.returns_net_loss, 0)) / COALESCE(sa.store_net_profit, 0)
    END AS web_to_store_profit_ratio,
    RANK() OVER (
        PARTITION BY COALESCE(sa.month, wa.month)
        ORDER BY (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) - COALESCE(wa.returns_net_loss, 0)) DESC
    ) AS profit_rank
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.p_promo_name = wa.p_promo_name
   AND sa.month = wa.month
   AND sa.holiday_flag = wa.holiday_flag
ORDER BY month, profit_rank
