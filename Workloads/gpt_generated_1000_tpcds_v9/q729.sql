WITH base AS (
   SELECT
       cs.cs_item_sk AS i_item_sk,
       cs.cs_ship_mode_sk AS ship_mode_sk,
       cs.cs_sold_time_sk AS sold_time_sk,
       cs.cs_quantity AS cs_quantity,
       cs.cs_ext_sales_price AS cs_sales,
       cs.cs_net_profit AS cs_profit,
       ws.ws_quantity AS ws_quantity,
       ws.ws_ext_sales_price AS ws_sales,
       ws.ws_net_profit AS ws_profit,
       i.i_category,
       i.i_class,
       i.i_item_desc,
       sm.sm_type,
       td.t_hour,
       ws.ws_net_paid_inc_ship,
       ws.ws_coupon_amt,
       ws.ws_ship_customer_sk,
       ws.ws_web_site_sk,
       web.web_country
   FROM catalog_sales cs
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site web
     ON ws.ws_web_site_sk = web.web_site_sk
   WHERE cs.cs_ext_list_price > 1000
     AND ws.ws_net_paid_inc_ship > 2000
     AND i.i_class = 'accessories'
     AND sm.sm_type = 'AIR'
     AND td.t_hour BETWEEN 8 AND 18
     AND web.web_country = 'United States'
     AND ws.ws_coupon_amt < 500
),
aggregated AS (
   SELECT
       i_item_sk,
       i_category,
       i_class,
       sm_type,
       t_hour,
       SUM(cs_sales) AS total_catalog_sales,
       SUM(ws_sales) AS total_web_sales,
       SUM(cs_profit + ws_profit) AS total_profit,
       COUNT(*) AS txn_count,
       ARRAY[SUM(cs_quantity), SUM(ws_quantity)] AS qty_array,
       CASE WHEN SUM(cs_profit + ws_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_flag
   FROM base
   GROUP BY i_item_sk, i_category, i_class, sm_type, t_hour
)
SELECT
    ag.i_item_sk,
    ag.i_category,
    ag.i_class,
    ag.sm_type,
    ag.t_hour,
    ag.total_catalog_sales,
    ag.total_web_sales,
    ag.total_profit,
    ag.txn_count,
    qty_val AS qty_per_type,
    ag.profit_flag
FROM aggregated ag
CROSS JOIN UNNEST(ag.qty_array) AS t(qty_val)
WHERE ag.total_profit > (SELECT AVG(total_profit) FROM aggregated)
ORDER BY ag.total_profit DESC
LIMIT 100
