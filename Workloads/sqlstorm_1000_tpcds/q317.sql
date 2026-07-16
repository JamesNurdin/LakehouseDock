WITH sales_agg AS (
    SELECT
        s.s_state,
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_returns_loss,
        SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
       AND sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_state, i.i_category, d.d_year, d.d_moy
)
SELECT
    s_state,
    i_category,
    d_year,
    d_moy,
    total_sales,
    net_profit_after_returns
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY net_profit_after_returns DESC) AS rn
    FROM sales_agg
) t
WHERE rn <= 10
ORDER BY s_state, rn
