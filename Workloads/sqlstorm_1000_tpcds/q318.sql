WITH catalog_sales_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           cs.cs_net_paid_inc_tax AS net_paid,
           cs.cs_net_profit AS profit,
           cs.cs_quantity AS quantity,
           cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
store_sales_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           ss.ss_net_paid_inc_tax AS net_paid,
           ss.ss_net_profit AS profit,
           ss.ss_quantity AS quantity,
           ss.ss_item_sk AS item_sk,
           ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
web_sales_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           ws.ws_net_paid_inc_tax AS net_paid,
           ws.ws_net_profit AS profit,
           ws.ws_quantity AS quantity,
           ws.ws_item_sk AS item_sk,
           ws.ws_sold_date_sk AS date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
all_sales AS (
    SELECT * FROM catalog_sales_cte
    UNION ALL
    SELECT * FROM store_sales_cte
    UNION ALL
    SELECT * FROM web_sales_cte
),
catalog_returns_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS quantity,
           cr.cr_item_sk AS item_sk,
           cr.cr_returned_date_sk AS date_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
store_returns_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_quantity AS quantity,
           sr.sr_item_sk AS item_sk,
           sr.sr_returned_date_sk AS date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
web_returns_cte AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS quantity,
           wr.wr_item_sk AS item_sk,
           wr.wr_returned_date_sk AS date_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
all_returns AS (
    SELECT * FROM catalog_returns_cte
    UNION ALL
    SELECT * FROM store_returns_cte
    UNION ALL
    SELECT * FROM web_returns_cte
),
sales_agg AS (
    SELECT d_year,
           d_month_seq,
           i_category,
           i_brand,
           SUM(net_paid) AS total_sales,
           SUM(profit) AS total_profit,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT item_sk) AS distinct_items_sold,
           COUNT(DISTINCT date_sk) AS active_sales_days
    FROM all_sales
    GROUP BY d_year, d_month_seq, i_category, i_brand
),
returns_agg AS (
    SELECT d_year,
           d_month_seq,
           i_category,
           i_brand,
           SUM(net_loss) AS total_returns_loss,
           SUM(quantity) AS total_return_quantity,
           COUNT(DISTINCT item_sk) AS distinct_items_returned,
           COUNT(DISTINCT date_sk) AS active_return_days
    FROM all_returns
    GROUP BY d_year, d_month_seq, i_category, i_brand
),
final AS (
    SELECT s.d_year,
           s.d_month_seq,
           s.i_category,
           s.i_brand,
           s.total_sales,
           s.total_profit,
           COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
           s.total_sales - COALESCE(r.total_returns_loss, 0) AS net_sales,
           s.total_profit - COALESCE(r.total_returns_loss, 0) AS net_profit_adj,
           s.total_quantity,
           COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
           s.distinct_items_sold,
           COALESCE(r.distinct_items_returned, 0) AS distinct_items_returned,
           ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS rank_by_sales
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.i_category = r.i_category
       AND s.i_brand = r.i_brand
)
SELECT *
FROM final
WHERE rank_by_sales <= 10
ORDER BY d_year, d_month_seq, rank_by_sales
