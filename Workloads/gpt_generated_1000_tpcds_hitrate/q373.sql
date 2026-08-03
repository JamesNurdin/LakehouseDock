WITH joined AS (
   SELECT
       ws.ws_web_site_sk,
       ws.ws_sold_date_sk,
       ws.ws_ext_sales_price,
       ws.ws_quantity,
       ws.ws_list_price,
       ws.ws_ext_list_price,
       ws.ws_ext_discount_amt,
       ws.ws_net_profit,
       wr.wr_return_amt,
       wr.wr_fee,
       ws_site.web_site_id,
       ws_site.web_manager,
       ws_site.web_gmt_offset
   FROM tpcds.web_sales ws
   JOIN tpcds.web_site ws_site
     ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN tpcds.web_returns wr
     ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
   WHERE ws.ws_ext_list_price > 1000
     AND ws.ws_quantity >= 2
     AND ws_site.web_gmt_offset BETWEEN -5 AND 5
     AND ws_site.web_manager IN ('Adam Stonge', 'John Ward')
     AND ws.ws_list_price < 2000
),
agg1 AS (
   SELECT
       web_site_id,
       ws_sold_date_sk,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(wr_return_amt) AS total_returns,
       COUNT(*) AS txn_cnt,
       CASE WHEN SUM(ws_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
       ARRAY[SUM(ws_ext_sales_price), SUM(wr_return_amt)] AS amount_array
   FROM joined
   GROUP BY GROUPING SETS (
       (web_site_id),
       (web_site_id, ws_sold_date_sk)
   )
),
unnested AS (
   SELECT
       a.web_site_id,
       a.ws_sold_date_sk,
       a.total_sales,
       a.total_returns,
       a.txn_cnt,
       a.sales_category,
       amt AS amount,
       ROW_NUMBER() OVER (PARTITION BY a.web_site_id ORDER BY a.total_sales DESC) AS sales_rank
   FROM agg1 a
   CROSS JOIN UNNEST(a.amount_array) AS t(amt)
),
final AS (
   SELECT
       u.web_site_id,
       u.ws_sold_date_sk,
       u.amount,
       u.sales_category,
       u.sales_rank,
       SUM(u.amount) OVER (PARTITION BY u.web_site_id ORDER BY u.amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_amount_sum,
       dm.web_manager,
       v.dummy
   FROM unnested u
   CROSS JOIN (SELECT DISTINCT web_manager FROM tpcds.web_site WHERE web_manager IN ('Adam Stonge', 'John Ward')) dm
   CROSS JOIN (VALUES (1), (2)) AS v(dummy)
   WHERE u.amount > 0
)
SELECT *
FROM final
WHERE running_amount_sum > 5000
ORDER BY web_site_id, ws_sold_date_sk
LIMIT 100
