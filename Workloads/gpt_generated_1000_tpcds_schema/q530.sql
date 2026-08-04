WITH
  sales_agg AS (
    SELECT
      cp.cp_department AS department,
      p.p_channel_catalog AS channel,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'Y'
    GROUP BY cp.cp_department, p.p_channel_catalog
  ),
  returns_agg AS (
    SELECT
      cp.cp_department AS department,
      p.p_channel_catalog AS channel,
      -SUM(cr.cr_return_amount) AS total_profit,
      COUNT(DISTINCT cr.cr_order_number) AS orders
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE p.p_channel_catalog = 'Y'
    GROUP BY cp.cp_department, p.p_channel_catalog
  ),
  -- set operation combining the two aggregates
  union_set AS (
    SELECT department, channel, total_profit, orders FROM sales_agg
    UNION ALL
    SELECT department, channel, total_profit, orders FROM returns_agg
  ),
  -- re‑aggregate after the UNION ALL
  agg_union AS (
    SELECT
      department,
      channel,
      SUM(total_profit) AS net_profit,
      SUM(orders) AS total_orders
    FROM union_set
    GROUP BY department, channel
  ),
  -- full outer join keeping unmatched rows from both sides
  full_join AS (
    SELECT
      COALESCE(s.department, r.department) AS department,
      COALESCE(s.channel, r.channel) AS channel,
      COALESCE(s.total_profit, 0) + COALESCE(r.total_profit, 0) AS net_profit
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.department = r.department AND s.channel = r.channel
  ),
  -- expand an array with UNNEST
  sales_detail AS (
    SELECT
      cs.cs_order_number,
      cp.cp_department AS department,
      p.p_channel_catalog AS channel,
      t.metric_name,
      t.metric_val
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(
      ARRAY[cs.cs_quantity, cs.cs_sales_price],
      ARRAY['quantity', 'sales_price']
    ) AS t(metric_val, metric_name)
    WHERE p.p_channel_catalog = 'Y'
  ),
  -- ranking per department with a correlated scalar subquery
  ranked AS (
    SELECT
      a.department,
      a.channel,
      a.net_profit,
      (
        SELECT COUNT(DISTINCT cs.cs_item_sk)
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_department = a.department
      ) AS distinct_items_sold,
      (
        SELECT AVG(sd.metric_val)
        FROM sales_detail sd
        WHERE sd.department = a.department
          AND sd.metric_name = 'sales_price'
      ) AS avg_sales_price,
      ROW_NUMBER() OVER (PARTITION BY a.department ORDER BY a.net_profit DESC) AS rnk
    FROM agg_union a
  )
SELECT
  r.department,
  r.channel,
  r.net_profit,
  r.distinct_items_sold,
  r.avg_sales_price,
  r.rnk
FROM ranked r
WHERE r.rnk <= 3
ORDER BY r.department, r.rnk
LIMIT 100
