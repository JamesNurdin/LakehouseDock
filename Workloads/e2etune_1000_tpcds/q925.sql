WITH cat_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt,
           0 AS total_fee,
           0 AS return_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 1
      AND cp.cp_type = 'monthly'
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt,
           0 AS total_fee,
           0 AS return_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 1
    GROUP BY i.i_category
),
returns_agg AS (
    SELECT i.i_category AS category,
           -SUM(cr.cr_net_loss) AS net_profit,
           0 AS total_discount,
           0 AS sales_cnt,
           SUM(cr.cr_fee) AS total_fee,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 1
      AND cp.cp_type = 'monthly'
    GROUP BY i.i_category
),
combined AS (
    SELECT * FROM cat_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM returns_agg
),
agg_final AS (
    SELECT category,
           SUM(net_profit) AS total_net_profit,
           SUM(total_discount) AS total_discount,
           SUM(sales_cnt) AS total_sales_cnt,
           SUM(total_fee) AS total_fee,
           SUM(return_cnt) AS total_return_cnt
    FROM combined
    GROUP BY category
)
SELECT category,
       total_net_profit,
       total_discount,
       total_sales_cnt,
       total_fee,
       total_return_cnt,
       ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_final
ORDER BY total_net_profit DESC
LIMIT 10
