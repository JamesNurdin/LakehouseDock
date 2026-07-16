WITH month_keys AS (
    SELECT DISTINCT d.d_year,
           d.d_month_seq,
           d.d_moy,
           CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month
    FROM date_dim d
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
),
store_month_keys AS (
    SELECT s.s_store_sk,
           mk.d_year,
           mk.d_month_seq,
           mk.d_moy,
           mk.year_month
    FROM store s
    CROSS JOIN month_keys mk
),
store_sales_agg AS (
    SELECT ss.ss_store_sk AS store_sk,
           d.d_year,
           d.d_month_seq,
           d.d_moy,
           CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq, d.d_moy
),
store_monthly_sales AS (
    SELECT sm.s_store_sk,
           sm.d_year,
           sm.d_month_seq,
           sm.d_moy,
           sm.year_month,
           COALESCE(agg.total_profit, 0) AS total_profit,
           COALESCE(agg.total_quantity, 0) AS total_quantity,
           COALESCE(agg.distinct_tickets, 0) AS distinct_tickets
    FROM store_month_keys sm
    LEFT JOIN store_sales_agg agg
       ON sm.s_store_sk = agg.store_sk
      AND sm.d_year = agg.d_year
      AND sm.d_month_seq = agg.d_month_seq
),
catalog_sales_agg AS (
    SELECT cs.cs_call_center_sk AS entity_id,
           d.d_year,
           d.d_month_seq,
           d.d_moy,
           CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY cs.cs_call_center_sk, d.d_year, d.d_month_seq, d.d_moy
),
web_sales_agg AS (
    SELECT ws.ws_web_page_sk AS entity_id,
           d.d_year,
           d.d_month_seq,
           d.d_moy,
           CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY ws.ws_web_page_sk, d.d_year, d.d_month_seq, d.d_moy
),
combined_sales AS (
    SELECT CAST(s.s_store_sk AS VARCHAR) AS entity_id,
           s.s_store_name AS entity_name,
           'store' AS channel,
           sm.d_year,
           sm.d_month_seq,
           sm.year_month,
           sm.total_profit,
           sm.total_quantity,
           sm.distinct_tickets
    FROM store_monthly_sales sm
    JOIN store s ON sm.s_store_sk = s.s_store_sk
    UNION ALL
    SELECT CAST(cc.cc_call_center_sk AS VARCHAR) AS entity_id,
           cc.cc_name AS entity_name,
           'catalog' AS channel,
           ca.d_year,
           ca.d_month_seq,
           ca.year_month,
           ca.total_profit,
           ca.total_quantity,
           NULL AS distinct_tickets
    FROM catalog_sales_agg ca
    JOIN call_center cc ON ca.entity_id = cc.cc_call_center_sk
    UNION ALL
    SELECT CAST(wp.wp_web_page_sk AS VARCHAR) AS entity_id,
           wp.wp_url AS entity_name,
           'web' AS channel,
           wa.d_year,
           wa.d_month_seq,
           wa.year_month,
           wa.total_profit,
           wa.total_quantity,
           NULL AS distinct_tickets
    FROM web_sales_agg wa
    JOIN web_page wp ON wa.entity_id = wp.wp_web_page_sk
),
store_avg_monthly_profit AS (
    SELECT s.s_store_sk,
           AVG(sm.total_profit) AS avg_monthly_profit
    FROM store s
    LEFT JOIN store_monthly_sales sm ON s.s_store_sk = sm.s_store_sk
    GROUP BY s.s_store_sk
),
final_ranking AS (
    SELECT cs.*,
           ROW_NUMBER() OVER (PARTITION BY cs.channel, cs.year_month ORDER BY cs.total_profit DESC) AS channel_month_rank,
           SUM(cs.total_profit) OVER (PARTITION BY cs.channel, cs.year_month) AS channel_month_total_profit,
           AVG(cs.total_profit) OVER (PARTITION BY cs.channel, cs.year_month) AS channel_month_avg_profit
    FROM combined_sales cs
)
SELECT fr.entity_id,
       fr.entity_name,
       fr.channel,
       fr.year_month,
       fr.total_profit,
       fr.total_quantity,
       fr.distinct_tickets,
       fr.channel_month_rank,
       fr.channel_month_total_profit,
       fr.channel_month_avg_profit,
       fr.profit_monthly_change,
       CASE 
           WHEN fr.profit_monthly_change IS NULL THEN 'N/A'
           WHEN fr.profit_monthly_change > 0 THEN 'UP'
           WHEN fr.profit_monthly_change < 0 THEN 'DOWN'
           ELSE 'FLAT'
       END AS profit_trend,
       CONCAT('Profit_', COALESCE(fr.channel, 'unknown')) AS profit_label,
       round(fr.total_profit / NULLIF(fr.total_quantity, 0) * 100, 2) AS profit_margin_pct,
       COALESCE(
          (SELECT sap.avg_monthly_profit 
           FROM store_avg_monthly_profit sap 
           WHERE sap.s_store_sk = CAST(fr.entity_id AS INTEGER)), 
          0) AS store_avg_monthly_profit
FROM (
    SELECT fr.*,
           fr.total_profit - LAG(fr.total_profit) OVER (PARTITION BY fr.entity_id ORDER BY fr.year_month) AS profit_monthly_change
    FROM final_ranking fr
) fr
WHERE fr.channel = 'store'
  AND fr.year_month BETWEEN '1998-01' AND '1998-12'
ORDER BY fr.channel, fr.year_month, fr.channel_month_rank
LIMIT 200
