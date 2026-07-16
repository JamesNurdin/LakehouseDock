WITH filtered_sales AS (
    SELECT i.i_category,
           i.i_brand,
           i.i_size,
           i.i_formulation,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_manager_id = 26
      AND i.i_size = 'large'
      AND i.i_formulation LIKE '%steel%'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
),
agg_sales AS (
    SELECT fs.i_category,
           fs.i_brand,
           SUM(fs.ws_ext_sales_price) AS total_sales,
           SUM(fs.ws_net_profit) AS total_profit,
           AVG(fs.ws_ext_discount_amt) AS avg_discount,
           COUNT(*) AS txn_cnt
    FROM filtered_sales fs
    GROUP BY fs.i_category, fs.i_brand
    HAVING SUM(fs.ws_ext_sales_price) > 5000
)
SELECT a.i_category,
       a.i_brand,
       a.total_sales,
       a.total_profit,
       a.avg_discount,
       a.txn_cnt,
       RANK() OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC) AS sales_rank_in_category
FROM agg_sales a
ORDER BY a.total_profit DESC
LIMIT 100
