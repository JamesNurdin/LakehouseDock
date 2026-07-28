/*
  Goal: Analyze store sales performance by state and promotion, comparing overall and discount‑active promotions, ranking them by sales and profit, while excluding any promotion dates that also have an advertising web page.
*/
WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk      AS d_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        ca.ca_state,
        p.p_promo_id,
        p.p_discount_active,
        p.p_response_target,
        wp.wp_type
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_page wp       ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_channel_radio   = 'N'
      AND p.p_response_target >= 1
      AND ss.ss_sales_price   > 10
      AND ca.ca_state         = 'CA'
      AND d.d_year            = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type          = 'product'
),
agg_all AS (
    SELECT
        ca_state,
        p_promo_id,
        d_date_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_net_profit)  AS total_profit,
        COUNT(*)            AS txn_cnt,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM sales_base
    GROUP BY CUBE (ca_state, p_promo_id, d_date_sk)
),
agg_discount AS (
    SELECT
        ca_state,
        p_promo_id,
        d_date_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_net_profit)  AS total_profit,
        COUNT(*)            AS txn_cnt,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM sales_base
    WHERE p_discount_active = 'Y'
    GROUP BY ROLLUP (ca_state, p_promo_id, d_date_sk)
),
union_agg AS (
    SELECT * FROM agg_all
    UNION ALL
    SELECT * FROM agg_discount
),
ranked AS (
    SELECT
        ca_state,
        p_promo_id,
        d_date_sk,
        total_sales,
        total_profit,
        txn_cnt,
        profit_flag,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS rn_state_sales,
        RANK()        OVER (ORDER BY total_profit DESC)               AS overall_profit_rank
    FROM union_agg
),
final AS (
    SELECT *
    FROM ranked r
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_creation_date_sk = r.d_date_sk
          AND wp.wp_type = 'ad'
    )
)
SELECT
    ca_state,
    p_promo_id,
    d_date_sk,
    total_sales,
    total_profit,
    txn_cnt,
    profit_flag,
    rn_state_sales,
    overall_profit_rank
FROM final
ORDER BY overall_profit_rank, rn_state_sales
LIMIT 100
