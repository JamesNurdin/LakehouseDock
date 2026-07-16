WITH store_agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        AVG(CASE WHEN ss.ss_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS store_promo_usage_rate
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY s.s_store_name, s.s_state, d.d_year, d.d_month_seq, i.i_category
    HAVING SUM(ss.ss_net_profit) > 10000
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category,
    sa.store_net_profit,
    ca.catalog_net_profit,
    sa.store_total_discount,
    ca.catalog_total_discount,
    sa.store_transactions,
    ca.catalog_orders,
    sa.store_promo_usage_rate
FROM store_agg sa
JOIN catalog_agg ca
  ON sa.d_year = ca.d_year
 AND sa.d_month_seq = ca.d_month_seq
 AND sa.i_category = ca.i_category
ORDER BY sa.store_net_profit DESC
LIMIT 100
