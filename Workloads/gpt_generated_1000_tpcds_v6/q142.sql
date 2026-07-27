WITH sales_base AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ss.ss_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_address_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        s.s_state = 'CA'
        AND s.s_city IN ('Springfield', 'Riverside')
        AND cd.cd_credit_rating = 'Good'
        AND cd.cd_purchase_estimate > 5000
        AND hd.hd_buy_potential = '5001-10000'
        AND ib.ib_lower_bound >= 50000
        AND ss.ss_quantity >= 2
        AND ss.ss_net_profit > 0
),
aggregated_sales AS (
    SELECT
        sb.s_store_id,
        sb.s_store_name,
        sb.s_city,
        sb.s_state,
        sb.p_promo_id,
        sb.p_promo_name,
        SUM(sb.ss_net_profit) AS total_profit,
        SUM(sb.ss_net_paid) AS total_paid,
        COUNT(*) AS transaction_count
    FROM sales_base sb
    GROUP BY
        sb.s_store_id,
        sb.s_store_name,
        sb.s_city,
        sb.s_state,
        sb.p_promo_id,
        sb.p_promo_name
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.p_promo_id,
    a.p_promo_name,
    a.total_profit,
    a.total_paid,
    a.transaction_count,
    CASE
        WHEN a.total_profit / NULLIF(a.total_paid, 0) > 0.20 THEN 'High Margin'
        WHEN a.total_profit / NULLIF(a.total_paid, 0) > 0.10 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS profit_category,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank,
    SUM(a.total_profit) OVER (
        PARTITION BY a.s_city
        ORDER BY a.total_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_city_profit
FROM aggregated_sales a
ORDER BY a.total_profit DESC
LIMIT 100
