WITH base_join AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_details,
        split(p.p_channel_details, ',') AS channel_array,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM household_demographics hd
    INNER JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_dep_count <= 5
        AND p.p_discount_active = 'Y'
        AND ws.ws_quantity > 0
        AND EXISTS (
            SELECT 1
            FROM income_band ib
            WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
              AND ib.ib_lower_bound >= 60000
        )
),
unnested AS (
    SELECT
        bj.*,
        TRIM(channel) AS channel
    FROM base_join bj
    CROSS JOIN UNNEST(bj.channel_array) AS t (channel)
),
agg AS (
    SELECT
        hd_demo_sk,
        p_promo_name,
        COUNT(DISTINCT channel) AS distinct_channel_count,
        SUM(cs_net_paid + ss_net_paid + ws_net_paid) AS total_net_paid,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        AVG(CASE WHEN (cs_net_profit + ss_net_profit + ws_net_profit) > 0 THEN 1 ELSE 0 END) AS pct_positive_profit,
        SUM(cs_ext_sales_price) / NULLIF(SUM(cs_net_paid), 0) AS catalog_price_to_paid_ratio
    FROM unnested
    GROUP BY hd_demo_sk, p_promo_name
    HAVING SUM(cs_net_paid + ss_net_paid + ws_net_paid) > 10000
)
SELECT
    hd_demo_sk,
    p_promo_name,
    distinct_channel_count,
    total_net_paid,
    total_catalog_sales,
    total_store_sales,
    total_web_sales,
    pct_positive_profit,
    catalog_price_to_paid_ratio,
    ROW_NUMBER() OVER (PARTITION BY hd_demo_sk ORDER BY total_net_paid DESC) AS rn,
    AVG(total_net_paid) OVER () AS avg_total_net_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
