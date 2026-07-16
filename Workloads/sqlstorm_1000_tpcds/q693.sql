WITH
raw_sales AS (
  SELECT
    ss.ss_store_sk AS entity_sk,
    d.d_year AS sale_year,
    d.d_date AS sale_date,
    ss.ss_net_profit AS profit,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE ss.ss_quantity > 0 AND mod(ss.ss_quantity, 2) = 1

  UNION ALL

  SELECT
    cs.cs_call_center_sk,
    d.d_year,
    d.d_date,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_net_paid,
    'catalog'
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE cs.cs_quantity > 0 AND cs.cs_net_paid IS NOT NULL

  UNION ALL

  SELECT
    ws.ws_web_page_sk,
    d.d_year,
    d.d_date,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_net_paid,
    'web'
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE ws.ws_quantity > 0 AND ws.ws_net_paid > 0
),
agg_sales AS (
  SELECT
    entity_sk AS store_sk,
    sale_year,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    MIN(sale_date) AS min_sale_date,
    MAX(sale_date) AS max_sale_date
  FROM raw_sales
  GROUP BY entity_sk, sale_year
),
ranked_sales AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.sale_year ORDER BY a.total_profit DESC) AS profit_rank,
    SUM(a.total_profit) OVER (PARTITION BY a.sale_year ORDER BY a.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    CASE WHEN a.total_profit < 0 THEN 'NEG' WHEN a.total_profit = 0 THEN 'ZERO' ELSE 'POS' END AS profit_sign,
    (date_diff('day', a.min_sale_date, a.max_sale_date) + 1) AS date_range_days,
    IF(date_diff('day', a.min_sale_date, a.max_sale_date) + 1 = 0,
       a.total_profit,
       a.total_profit / (date_diff('day', a.min_sale_date, a.max_sale_date) + 1)
      ) AS profit_per_day,
    (SELECT COUNT(*) FROM agg_sales a2 WHERE a2.sale_year = a.sale_year AND a2.total_profit > a.total_profit) AS num_entities_higher,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_store_sk = a.store_sk) AS store_exists_flag
  FROM agg_sales a
)
SELECT
  rs.sale_year AS year,
  rs.store_sk,
  rs.total_profit,
  rs.total_quantity,
  rs.transaction_cnt,
  rs.profit_rank,
  rs.cumulative_profit,
  rs.profit_sign,
  rs.date_range_days,
  rs.profit_per_day,
  rs.num_entities_higher,
  CASE
    WHEN rs.store_exists_flag = 0 THEN 'UNKNOWN_ENTITY'
    ELSE COALESCE(st.s_store_name, cc.cc_name, wp.wp_url, 'UNKNOWN')
  END AS entity_name,
  COALESCE(st.s_state, cc.cc_state, 'N/A') AS location,
  CONCAT('Y', CAST(rs.sale_year AS VARCHAR), '-', LPAD(CAST(rs.profit_rank AS VARCHAR), 2, '0')) AS rank_label,
  IF(rs.total_profit > 50000, 'HIGH', 'NORMAL') AS profit_class
FROM ranked_sales rs
LEFT JOIN store st ON rs.store_sk = st.s_store_sk
LEFT JOIN call_center cc ON rs.store_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp ON rs.store_sk = wp.wp_web_page_sk
WHERE rs.profit_rank <= 10
ORDER BY rs.sale_year, rs.profit_rank
