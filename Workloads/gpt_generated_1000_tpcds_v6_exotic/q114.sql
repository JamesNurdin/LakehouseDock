WITH store_profit AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS txn_count,
    AVG(ss.ss_net_profit) AS avg_profit
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
    AND i.i_product_name LIKE '%BLUE%'
    AND regexp_like(c.c_email_address, '@example\\.com$')
  GROUP BY s.s_store_id, s.s_store_name
)
SELECT
  sp.s_store_id,
  sp.s_store_name,
  sp.total_profit,
  sp.txn_count,
  sp.avg_profit,
  CASE
    WHEN sp.total_profit > (SELECT AVG(total_profit) FROM store_profit) THEN 'Above Avg'
    WHEN sp.total_profit > 50000 THEN 'High'
    ELSE 'Low'
  END AS profit_category,
  RANK() OVER (ORDER BY sp.total_profit DESC) AS profit_rank
FROM store_profit sp
ORDER BY sp.total_profit DESC
LIMIT 100
