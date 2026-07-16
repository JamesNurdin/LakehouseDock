WITH
store_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_item_id,
        SUM(ss.ss_quantity) AS quantity_sold,
        SUM(ss.ss_net_profit) AS net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MAX(ss.ss_sold_date_sk) AS max_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, i.i_item_id
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_item_id,
        SUM(cs.cs_quantity) AS quantity_sold,
        SUM(cs.cs_net_profit) AS net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MAX(cs.cs_sold_date_sk) AS max_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, i.i_item_id
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_item_id,
        SUM(ws.ws_quantity) AS quantity_sold,
        SUM(ws.ws_net_profit) AS net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        MAX(ws.ws_sold_date_sk) AS max_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, i.i_item_id
),
combined AS (
    SELECT d_year, d_quarter_seq, i_category, i_item_id, quantity_sold, net_profit, avg_discount, max_date_sk FROM store_agg
    UNION ALL
    SELECT d_year, d_quarter_seq, i_category, i_item_id, quantity_sold, net_profit, avg_discount, max_date_sk FROM catalog_agg
    UNION ALL
    SELECT d_year, d_quarter_seq, i_category, i_item_id, quantity_sold, net_profit, avg_discount, max_date_sk FROM web_agg
),
category_yearly AS (
    SELECT
        d_year,
        i_category,
        SUM(quantity_sold) AS total_quantity,
        SUM(net_profit) AS total_profit,
        AVG(avg_discount) AS avg_discount
    FROM combined
    GROUP BY d_year, i_category
),
category_yearly_with_prev AS (
    SELECT
        c.*,
        LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year) AS prev_year_profit,
        CASE 
            WHEN LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year) IS NULL THEN NULL
            WHEN LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year) = 0 THEN NULL
            ELSE (c.total_profit - LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year)) /
                LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year) * 100
        END AS profit_growth_pct
    FROM category_yearly c
),
promo_active AS (
    SELECT
        p.p_promo_id,
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        CASE 
            WHEN d.d_date_sk >= p.p_start_date_sk AND (p.p_end_date_sk IS NULL OR d.d_date_sk <= p.p_end_date_sk) THEN 1
            ELSE 0
        END AS is_active
    FROM promotion p
    JOIN date_dim d ON d.d_date_sk BETWEEN p.p_start_date_sk AND COALESCE(p.p_end_date_sk, d.d_date_sk)
),
item_category_promo AS (
    SELECT 
        i.i_category,
        MAX(CASE WHEN pa.is_active = 1 THEN 1 ELSE 0 END) AS has_active_promo
    FROM item i
    LEFT JOIN promo_active pa ON pa.p_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
final AS (
    SELECT 
        cywp.d_year,
        cywp.i_category,
        cywp.total_quantity,
        cywp.total_profit,
        cywp.avg_discount,
        cywp.profit_growth_pct,
        COALESCE(icp.has_active_promo, 0) AS active_promo_flag,
        CONCAT(cywp.i_category, '-', CAST(cywp.d_year AS VARCHAR)) AS category_year_key,
        CASE 
            WHEN cywp.total_profit > (SELECT AVG(total_profit) FROM category_yearly) THEN 'High'
            WHEN cywp.total_profit < (SELECT AVG(total_profit) FROM category_yearly) THEN 'Low'
            ELSE 'Medium'
        END AS profit_category,
        (SELECT MAX(cc.net_profit) FROM combined cc WHERE cc.i_category = cywp.i_category) AS max_category_profit
    FROM category_yearly_with_prev cywp
    LEFT JOIN item_category_promo icp ON icp.i_category = cywp.i_category
)
SELECT 
    category_year_key,
    i_category,
    d_year,
    total_quantity,
    total_profit,
    avg_discount,
    profit_growth_pct,
    active_promo_flag,
    profit_category,
    max_category_profit,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM final
WHERE (profit_growth_pct IS NULL OR profit_growth_pct > 5)
  AND COALESCE(total_quantity, 0) > 0
ORDER BY i_category, profit_rank
