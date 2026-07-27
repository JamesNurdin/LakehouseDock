/*
Goal: Identify the most profitable market‑manager/warehouse combinations for the current year, enriched with inventory on‑hand, store returns and website activity. The query aggregates sales first, then joins additional aggregates via LEFT OUTER JOINs, applies several filters, orders by sales and limits the result.
*/
WITH
  -- Aggregate catalog sales by year, month, market manager and warehouse
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cc.cc_market_manager,
      w.w_warehouse_name,
      SUM(cs.cs_ext_sales_price)      AS total_sales,
      SUM(cs.cs_net_profit)           AS total_profit,
      COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN date_dim d          ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    WHERE d.d_current_year = 'Y'
      AND d.d_current_month = 'Y'
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND w.w_gmt_offset IS NOT NULL
    GROUP BY
      d.d_year,
      d.d_month_seq,
      cc.cc_market_manager,
      w.w_warehouse_name
  ),

  -- Aggregate store returns by year and store name
  store_return_agg AS (
    SELECT
      d.d_year,
      s.s_store_name,
      SUM(sr.sr_return_amt) AS total_returns,
      COUNT(*)               AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s    ON sr.sr_store_sk         = s.s_store_sk
    WHERE d.d_current_year = 'Y'
      AND s.s_gmt_offset BETWEEN -5 AND 5
    GROUP BY d.d_year, s.s_store_name
  ),

  -- Aggregate inventory on‑hand by year and warehouse
  inventory_agg AS (
    SELECT
      d.d_year,
      w.w_warehouse_name,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk      = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_current_year = 'Y'
    GROUP BY d.d_year, w.w_warehouse_name
  ),

  -- Aggregate website information by year and site name
  website_agg AS (
    SELECT
      d.d_year,
      ws.web_name,
      COUNT(*) AS site_count
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
    GROUP BY d.d_year, ws.web_name
  )

SELECT
  sa.d_year,
  sa.cc_market_manager,
  sa.w_warehouse_name,
  sa.total_sales,
  sa.total_profit,
  COALESCE(ia.total_on_hand, 0)      AS total_on_hand,
  COALESCE(sra.total_returns, 0)    AS total_returns,
  COALESCE(wa.site_count, 0)        AS site_count,
  CASE WHEN COALESCE(ia.total_on_hand, 0) = 0 THEN NULL
       ELSE sa.total_sales / ia.total_on_hand END AS sales_per_onhand
FROM sales_agg sa
LEFT OUTER JOIN inventory_agg ia
  ON sa.d_year = ia.d_year
 AND sa.w_warehouse_name = ia.w_warehouse_name
LEFT OUTER JOIN store_return_agg sra
  ON sa.d_year = sra.d_year
LEFT OUTER JOIN website_agg wa
  ON sa.d_year = wa.d_year
WHERE sa.total_sales > 10000
  AND sa.total_profit > 0
  AND COALESCE(ia.total_on_hand, 0) > 0
  AND wa.site_count > 0
ORDER BY sa.total_sales DESC
LIMIT 100
