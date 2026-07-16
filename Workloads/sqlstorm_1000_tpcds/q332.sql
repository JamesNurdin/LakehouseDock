WITH sale_agg AS (
   SELECT ss_item_sk AS item_sk,
          ss_sold_date_sk AS sold_date_sk,
          SUM(ss_net_profit) AS store_profit,
          SUM(ss_quantity) AS store_qty,
          COUNT(DISTINCT ss_ticket_number) AS store_orders,
          MAX(ss_net_paid) AS max_store_net_paid
   FROM store_sales
   GROUP BY ss_item_sk, ss_sold_date_sk
), catalog_agg AS (
   SELECT cs_item_sk AS item_sk,
          cs_sold_date_sk AS sold_date_sk,
          SUM(cs_net_profit) AS catalog_profit,
          SUM(cs_quantity) AS catalog_qty,
          COUNT(DISTINCT cs_order_number) AS catalog_orders,
          MAX(cs_net_paid) AS max_catalog_net_paid
   FROM catalog_sales
   GROUP BY cs_item_sk, cs_sold_date_sk
), combined_sales AS (
   SELECT COALESCE(s.item_sk, c.item_sk) AS item_sk,
          COALESCE(s.sold_date_sk, c.sold_date_sk) AS sold_date_sk,
          s.store_profit,
          c.catalog_profit,
          s.store_qty,
          c.catalog_qty,
          s.store_orders,
          c.catalog_orders,
          s.max_store_net_paid,
          c.max_catalog_net_paid
   FROM sale_agg s
   FULL OUTER JOIN catalog_agg c
     ON s.item_sk = c.item_sk AND s.sold_date_sk = c.sold_date_sk
), sales_with_date AS (
   SELECT
          cs.item_sk,
          cs.sold_date_sk,
          d.d_year,
          d.d_month_seq,
          format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM-dd') AS sold_date_str,
          i.i_product_name,
          i.i_category,
          i.i_brand,
          COALESCE(cs.store_profit, 0) + COALESCE(cs.catalog_profit, 0) AS total_profit,
          COALESCE(cs.store_qty, 0) + COALESCE(cs.catalog_qty, 0) AS total_qty,
          CASE
            WHEN COALESCE(cs.store_profit, 0) + COALESCE(cs.catalog_profit, 0) > 0 THEN 'PROFIT'
            WHEN COALESCE(cs.store_profit, 0) + COALESCE(cs.catalog_profit, 0) < 0 THEN 'LOSS'
            ELSE 'ZERO'
          END AS profit_status,
          ROW_NUMBER() OVER (PARTITION BY i.i_category, d.d_year ORDER BY COALESCE(cs.store_profit, 0) + COALESCE(cs.catalog_profit, 0) DESC) AS category_year_rank,
          (SELECT AVG(COALESCE(s2.store_profit,0) + COALESCE(s2.catalog_profit,0))
           FROM combined_sales s2
           WHERE s2.item_sk = cs.item_sk
                 AND s2.sold_date_sk < cs.sold_date_sk) AS avg_prior_profit,
          NULLIF(COALESCE(cs.store_profit,0) + COALESCE(cs.catalog_profit,0), 0) AS profit_nonzero_check
   FROM combined_sales cs
   LEFT JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON cs.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
), final_result AS (
   SELECT
          swd.d_year,
          swd.i_category,
          swd.i_brand,
          swd.item_sk,
          swd.i_product_name,
          swd.total_qty,
          swd.total_profit,
          swd.profit_status,
          swd.category_year_rank,
          swd.avg_prior_profit,
          COALESCE(swd.avg_prior_profit, 0) - swd.total_profit AS profit_delta,
          CASE 
            WHEN COALESCE(swd.avg_prior_profit, 0) - swd.total_profit > 0 THEN 'DECLINE'
            WHEN COALESCE(swd.avg_prior_profit, 0) - swd.total_profit < 0 THEN 'GROWTH'
            ELSE 'STABLE'
          END AS profit_trend,
          CONCAT(swd.i_brand, ' - ', swd.i_product_name) AS brand_product,
          COALESCE(cc.cc_name, 'UNKNOWN_CC') AS call_center_name
   FROM sales_with_date swd
   LEFT JOIN call_center cc
     ON (swd.item_sk % 1000) = cc.cc_call_center_sk
   WHERE swd.total_qty > 0
     AND (swd.total_profit IS NOT NULL OR swd.profit_status = 'ZERO')
)
SELECT
    d_year,
    i_category,
    i_brand,
    item_sk,
    i_product_name,
    total_qty,
    total_profit,
    profit_status,
    category_year_rank,
    avg_prior_profit,
    profit_delta,
    profit_trend,
    brand_product,
    call_center_name
FROM final_result
UNION ALL
SELECT
    d_year,
    i_category,
    i_brand,
    item_sk,
    i_product_name,
    -total_qty AS total_qty,
    -total_profit AS total_profit,
    profit_status,
    -category_year_rank AS category_year_rank,
    avg_prior_profit,
    profit_delta,
    profit_trend,
    brand_product,
    call_center_name
FROM final_result
WHERE profit_status = 'LOSS'
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
