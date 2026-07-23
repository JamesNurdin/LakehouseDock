WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND d.d_year BETWEEN 1999 AND 2001
        AND s.s_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ss.ss_promo_sk
              AND p.p_channel_email = 'Y'
              AND p.p_discount_active = 'Y'
        )
    GROUP BY
        s.s_store_id,
        s.s_state,
        d.d_year
),
store_yearly_avg AS (
    SELECT
        s_store_id,
        s_state,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(total_sales) AS avg_sales,
        SUM(txn_count) AS total_txn
    FROM sales_agg
    GROUP BY
        s_store_id,
        s_state
)
SELECT
    s_store_id AS store_id,
    s_state AS state,
    avg_net_profit,
    avg_sales,
    total_txn,
    avg_net_profit / NULLIF(avg_sales, 0) AS avg_profit_margin
FROM store_yearly_avg
WHERE avg_net_profit > 50000
ORDER BY avg_profit_margin DESC, avg_net_profit DESC
LIMIT 50
