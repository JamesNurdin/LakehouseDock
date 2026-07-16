WITH fact AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           'Catalog' AS channel,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit,
           cs.cs_ext_discount_amt AS discount,
           cs.cs_quantity AS quantity,
           cs.cs_item_sk AS item_sk,
           cc.cc_state AS state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           'Store',
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt,
           ss.ss_quantity,
           ss.ss_item_sk,
           s.s_state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'Web',
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt,
           ws.ws_quantity,
           ws.ws_item_sk,
           w.w_state
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT t.d_year,
       t.month,
       t.state,
       t.i_category,
       t.total_sales,
       t.total_profit,
       t.total_discount,
       t.total_quantity,
       t.median_profit,
       t.distinct_items_sold,
       t.profit_rank
FROM (
    SELECT d.d_year,
           d.d_month_seq AS month,
           f.state,
           i.i_category,
           SUM(f.sales_amount) AS total_sales,
           SUM(f.profit) AS total_profit,
           SUM(f.discount) AS total_discount,
           SUM(f.quantity) AS total_quantity,
           approx_percentile(f.profit, 0.5) AS median_profit,
           COUNT(DISTINCT f.item_sk) AS distinct_items_sold,
           SUM(f.profit) AS sum_profit,
           ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq, f.state ORDER BY SUM(f.profit) DESC) AS profit_rank
    FROM fact f
    JOIN date_dim d ON f.date_sk = d.d_date_sk
    JOIN item i ON f.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_current_price > 0
    GROUP BY d.d_year,
             d.d_month_seq,
             f.state,
             i.i_category
    HAVING SUM(f.sales_amount) > 10000
) t
WHERE t.profit_rank <= 5
ORDER BY t.d_year, t.month, t.state, t.profit_rank
