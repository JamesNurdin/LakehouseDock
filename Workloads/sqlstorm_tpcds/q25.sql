WITH
store_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'store' AS channel,
        s.s_state AS region,
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        approx_distinct(ss.ss_customer_sk) AS distinct_customers,
        approx_percentile(ss.ss_net_profit, 0.5) AS median_net_profit,
        COUNT(*) AS transaction_count,
        SUM(COALESCE(p.p_cost, 0)) AS total_promotion_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_moy, s.s_state, i.i_category, i.i_item_id
),
catalog_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'catalog' AS channel,
        CAST(NULL AS varchar) AS region,
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        approx_distinct(cs.cs_bill_customer_sk) AS distinct_customers,
        approx_percentile(cs.cs_net_profit, 0.5) AS median_net_profit,
        COUNT(*) AS transaction_count,
        SUM(COALESCE(p.p_cost, 0)) AS total_promotion_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_moy, i.i_category, i.i_item_id
),
web_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        'web' AS channel,
        CAST(NULL AS varchar) AS region,
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        approx_distinct(ws.ws_bill_customer_sk) AS distinct_customers,
        approx_percentile(ws.ws_net_profit, 0.5) AS median_net_profit,
        COUNT(*) AS transaction_count,
        SUM(COALESCE(p.p_cost, 0)) AS total_promotion_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_moy, i.i_category, i.i_item_id
),
combined_agg AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
item_monthly_profit AS (
    SELECT
        year,
        month,
        item_id,
        SUM(total_net_profit) AS item_monthly_profit
    FROM combined_agg
    GROUP BY year, month, item_id
),
item_monthly_rank AS (
    SELECT
        year,
        month,
        item_id,
        item_monthly_profit,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY item_monthly_profit DESC) AS rank
    FROM item_monthly_profit
),
final_agg AS (
    SELECT
        ca.year,
        ca.month,
        ca.channel,
        ca.region,
        ca.category,
        ca.item_id,
        ca.total_net_paid,
        ca.total_net_profit,
        ca.avg_discount,
        ca.total_quantity,
        ca.distinct_customers,
        ca.median_net_profit,
        ca.transaction_count,
        ca.total_promotion_cost,
        SUM(ca.total_net_profit) OVER (PARTITION BY ca.channel ORDER BY ca.year, ca.month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit,
        SUM(ca.total_promotion_cost) OVER (PARTITION BY ca.channel ORDER BY ca.year, ca.month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_promotion_cost,
        CASE WHEN imr.rank <= 5 THEN TRUE ELSE FALSE END AS top_5_item_in_month
    FROM combined_agg ca
    LEFT JOIN item_monthly_rank imr
        ON ca.year = imr.year
        AND ca.month = imr.month
        AND ca.item_id = imr.item_id
)
SELECT *
FROM final_agg
WHERE year BETWEEN 1999 AND 2001
ORDER BY year, month, channel, total_net_profit DESC
