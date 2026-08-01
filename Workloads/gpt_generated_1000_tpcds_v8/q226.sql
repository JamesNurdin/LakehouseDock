WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
agg_data AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
        ca.ca_state,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ca.ca_state) AS distinct_states,
        COUNT(DISTINCT p.p_promo_name) AS distinct_promo_names,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        regexp_extract(p.p_promo_name, '(?i)(sale)', 1) AS sale_word
    FROM sampled_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)sale')
      AND ca.ca_city LIKE 'A%'
      AND concat(cd.cd_gender, '-', cd.cd_marital_status) = 'M-M'
    GROUP BY p.p_promo_id, p.p_promo_name, ca.ca_city, ca.ca_state, ss.ss_item_sk
    HAVING COUNT(DISTINCT ca.ca_state) > 1
)
SELECT
    p_promo_id,
    p_promo_name,
    city_state,
    total_profit,
    distinct_states,
    distinct_promo_names,
    profit_flag,
    sale_word,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_profit DESC) AS profit_rank
FROM agg_data
ORDER BY total_profit DESC
LIMIT 100
