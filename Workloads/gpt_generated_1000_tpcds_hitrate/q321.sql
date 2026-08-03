WITH store_sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_street_type,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    hd.hd_buy_potential
  FROM store_sales ss
  RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_street_type,
    hd.hd_buy_potential
),
final AS (
  SELECT
    sa.s_store_name,
    sa.s_city,
    sa.s_street_type,
    sa.total_net_profit,
    sa.sales_count,
    regexp_extract(sa.hd_buy_potential, '(\\d+)-\\d+', 1) AS low_buy_potential,
    CASE
      WHEN regexp_like(sa.hd_buy_potential, '^>') THEN 'High'
      ELSE 'Low'
    END AS buy_potential_category,
    LAG(sa.total_net_profit) OVER (PARTITION BY sa.s_city ORDER BY sa.total_net_profit DESC) AS prev_city_profit,
    (SELECT AVG(total_net_profit) FROM store_sales_agg) AS overall_avg_profit,
    (SELECT AVG(inv_quantity_on_hand) FROM inventory TABLESAMPLE BERNOULLI (5)) AS sampled_avg_qty
  FROM store_sales_agg sa
  WHERE sa.s_street_type LIKE '%Drive%'
    AND sa.s_city LIKE '%York%'
    AND sa.total_net_profit > (SELECT AVG(total_net_profit) FROM store_sales_agg)
)
SELECT
  f.s_store_name,
  f.s_city,
  f.s_street_type,
  f.total_net_profit,
  f.sales_count,
  f.low_buy_potential,
  f.buy_potential_category,
  f.prev_city_profit,
  f.overall_avg_profit,
  f.sampled_avg_qty
FROM final f
ORDER BY f.total_net_profit DESC
LIMIT 100
