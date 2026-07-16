WITH
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS join_key,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS customer_cnt
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_store_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS join_key,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS customer_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_call_center_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_web_site_sk AS join_key,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_web_site_sk
),
unified_sales AS (
    SELECT
        date_sk,
        item_sk,
        net_paid,
        net_profit,
        customer_cnt,
        'store' AS channel,
        join_key
    FROM store_sales_agg
    UNION ALL
    SELECT
        date_sk,
        item_sk,
        net_paid,
        net_profit,
        customer_cnt,
        'catalog' AS channel,
        join_key
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        date_sk,
        item_sk,
        net_paid,
        net_profit,
        customer_cnt,
        'web' AS channel,
        join_key
    FROM web_sales_agg
),
sales_enriched AS (
    SELECT
        us.*,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_color,
        i.i_brand,
        p.p_promo_name,
        p.p_discount_active,
        CASE WHEN us.channel = 'store' THEN s.s_store_name END AS store_name,
        CASE WHEN us.channel = 'catalog' THEN cc.cc_name END AS call_center_name,
        CASE WHEN us.channel = 'web' THEN ws_dim.web_name END AS web_site_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON us.item_sk = p.p_item_sk
        AND us.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN store s ON us.channel = 'store' AND us.join_key = s.s_store_sk
    LEFT JOIN call_center cc ON us.channel = 'catalog' AND us.join_key = cc.cc_call_center_sk
    LEFT JOIN web_site ws_dim ON us.channel = 'web' AND us.join_key = ws_dim.web_site_sk
),
final_calc AS (
    SELECT
        se.d_year,
        se.d_month_seq,
        se.channel,
        concat(se.i_item_id, '-', se.i_product_name) AS product_full_name,
        se.store_name,
        se.call_center_name,
        se.web_site_name,
        se.net_paid,
        se.net_profit,
        CASE WHEN se.net_paid = 0 THEN NULL ELSE round(se.net_profit / se.net_paid * 100, 2) END AS profit_margin_pct,
        coalesce(se.p_discount_active, 'N') AS promotion_active,
        se.p_promo_name,
        se.customer_cnt,
        rank() OVER (PARTITION BY se.d_year, se.channel ORDER BY se.net_profit DESC) AS profit_rank_year_channel,
        lag(se.net_profit) OVER (PARTITION BY se.item_sk, se.channel ORDER BY se.d_month_seq) AS previous_month_profit,
        CASE
            WHEN lag(se.net_profit) OVER (PARTITION BY se.item_sk, se.channel ORDER BY se.d_month_seq) IS NULL
                 OR lag(se.net_profit) OVER (PARTITION BY se.item_sk, se.channel ORDER BY se.d_month_seq) = 0
            THEN NULL
            ELSE round(
                (se.net_profit - lag(se.net_profit) OVER (PARTITION BY se.item_sk, se.channel ORDER BY se.d_month_seq))
                / lag(se.net_profit) OVER (PARTITION BY se.item_sk, se.channel ORDER BY se.d_month_seq) * 100,
                2)
        END AS profit_change_pct,
        (
            SELECT SUM(uc.customer_cnt)
            FROM unified_sales uc
            JOIN date_dim d2 ON uc.date_sk = d2.d_date_sk
            WHERE uc.item_sk = se.item_sk
              AND uc.channel = se.channel
              AND d2.d_year = se.d_year
        ) AS total_customers_year_channel
    FROM sales_enriched se
    WHERE (se.d_year = 2001 OR se.d_year = 2002)
      AND (se.i_category = 'Books' OR se.i_category IS NULL)
      AND (coalesce(se.p_discount_active, 'N') = 'Y' OR se.channel = 'store')
)
SELECT *
FROM final_calc
WHERE profit_rank_year_channel <= 10
ORDER BY d_year, channel, profit_rank_year_channel
