WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(CASE WHEN ss.ss_ext_list_price > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_list_price END) * 100 AS avg_discount_pct
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
      AND d.d_quarter_name = 'Q4'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
)
SELECT
    s_store_id,
    s_store_name,
    i_category,
    total_profit,
    total_quantity,
    avg_discount_pct,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_profit DESC) AS category_profit_rank
FROM agg
ORDER BY s_store_id, category_profit_rank
LIMIT 200
