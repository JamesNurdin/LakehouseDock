WITH
store_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           s.s_store_sk,
           s.s_store_name,
           i.i_category,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_net_paid) AS net_sales,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, s.s_store_sk, s.s_store_name, i.i_category
),
store_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           s.s_store_sk,
           i.i_category,
           SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, s.s_store_sk, i.i_category
),
web_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           ws.ws_web_page_sk,
           i.i_category,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_net_paid) AS net_sales,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, ws.ws_web_page_sk, i.i_category
),
web_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           wr.wr_web_page_sk,
           i.i_category,
           SUM(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, wr.wr_web_page_sk, i.i_category
),
catalog_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           i.i_category,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_net_paid) AS net_sales,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           d.d_quarter_seq,
           i.i_category,
           SUM(cr.cr_net_loss) AS return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, d.d_quarter_seq, i.i_category
),
combined_sales AS (
    SELECT s.d_year,
           s.d_month_seq,
           s.d_quarter_seq,
           s.s_store_name AS store_name,
           NULL AS web_page_sk,
           s.i_category,
           s.net_profit AS store_net_profit,
           NULL AS web_net_profit,
           NULL AS catalog_net_profit,
           s.net_sales AS store_net_sales,
           NULL AS web_net_sales,
           NULL AS catalog_net_sales,
           s.distinct_customers AS store_distinct_customers,
           NULL AS web_distinct_customers,
           NULL AS catalog_distinct_customers,
           COALESCE(sr.return_loss, 0) AS store_return_loss,
           0 AS web_return_loss,
           0 AS catalog_return_loss
    FROM store_sales_agg s
    LEFT JOIN store_returns_agg sr
        ON sr.d_year = s.d_year
        AND sr.d_month_seq = s.d_month_seq
        AND sr.d_quarter_seq = s.d_quarter_seq
        AND sr.s_store_sk = s.s_store_sk
        AND sr.i_category = s.i_category

    UNION ALL

    SELECT ws.d_year,
           ws.d_month_seq,
           ws.d_quarter_seq,
           NULL,
           ws.ws_web_page_sk,
           ws.i_category,
           NULL,
           ws.net_profit,
           NULL,
           NULL,
           ws.net_sales,
           NULL,
           NULL,
           ws.distinct_customers,
           NULL,
           0,
           COALESCE(wr.return_loss, 0),
           0
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
        ON wr.d_year = ws.d_year
        AND wr.d_month_seq = ws.d_month_seq
        AND wr.d_quarter_seq = ws.d_quarter_seq
        AND wr.wr_web_page_sk = ws.ws_web_page_sk
        AND wr.i_category = ws.i_category

    UNION ALL

    SELECT cs.d_year,
           cs.d_month_seq,
           cs.d_quarter_seq,
           NULL,
           NULL,
           cs.i_category,
           NULL,
           NULL,
           cs.net_profit,
           NULL,
           NULL,
           cs.net_sales,
           NULL,
           NULL,
           cs.distinct_customers,
           0,
           0,
           COALESCE(cr.return_loss, 0)
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cr.d_year = cs.d_year
        AND cr.d_month_seq = cs.d_month_seq
        AND cr.d_quarter_seq = cs.d_quarter_seq
        AND cr.i_category = cs.i_category
),
final_agg AS (
    SELECT d_year,
           d_month_seq,
           d_quarter_seq,
           store_name,
           web_page_sk,
           i_category,
           SUM(COALESCE(store_net_profit, 0)) AS total_store_profit,
           SUM(COALESCE(web_net_profit, 0)) AS total_web_profit,
           SUM(COALESCE(catalog_net_profit, 0)) AS total_catalog_profit,
           SUM(COALESCE(store_net_sales, 0)) AS total_store_sales,
           SUM(COALESCE(web_net_sales, 0)) AS total_web_sales,
           SUM(COALESCE(catalog_net_sales, 0)) AS total_catalog_sales,
           SUM(COALESCE(store_distinct_customers, 0)) AS total_store_customers,
           SUM(COALESCE(web_distinct_customers, 0)) AS total_web_customers,
           SUM(COALESCE(catalog_distinct_customers, 0)) AS total_catalog_customers,
           SUM(store_return_loss) AS total_store_return_loss,
           SUM(web_return_loss) AS total_web_return_loss,
           SUM(catalog_return_loss) AS total_catalog_return_loss
    FROM combined_sales
    GROUP BY d_year, d_month_seq, d_quarter_seq, store_name, web_page_sk, i_category
),
top_item_per_quarter AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           i_item_id,
           sales_amount,
           ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, i_category ORDER BY sales_amount DESC) AS rn
    FROM (
        SELECT d.d_year,
               d.d_quarter_seq,
               i.i_category,
               i.i_item_id,
               SUM(cs.cs_ext_sales_price) AS sales_amount
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_quarter_seq, i.i_category, i.i_item_id
    )
)
SELECT
    f.d_year,
    f.d_month_seq,
    f.i_category,
    f.store_name,
    f.web_page_sk,
    f.total_store_profit,
    f.total_web_profit,
    f.total_catalog_profit,
    f.total_store_sales,
    f.total_web_sales,
    f.total_catalog_sales,
    (f.total_store_profit + f.total_web_profit + f.total_catalog_profit) -
        (f.total_store_return_loss + f.total_web_return_loss + f.total_catalog_return_loss) AS net_profit_after_returns,
    f.total_store_customers,
    f.total_web_customers,
    f.total_catalog_customers,
    f.total_store_return_loss,
    f.total_web_return_loss,
    f.total_catalog_return_loss,
    ROUND(100.0 * (f.total_store_return_loss + f.total_web_return_loss + f.total_catalog_return_loss) /
          NULLIF((f.total_store_sales + f.total_web_sales + f.total_catalog_sales), 0), 2) AS return_loss_percentage,
    SUM(f.total_store_profit) OVER (PARTITION BY f.store_name ORDER BY f.d_year, f.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS store_3_month_moving_profit,
    ti.i_item_id AS top_item_id,
    ti.sales_amount AS top_item_sales
FROM final_agg f
LEFT JOIN (
    SELECT d_year, d_quarter_seq, i_category, i_item_id, sales_amount
    FROM top_item_per_quarter
    WHERE rn = 1
) ti
    ON ti.d_year = f.d_year
    AND ti.d_quarter_seq = f.d_quarter_seq
    AND ti.i_category = f.i_category
WHERE f.d_year >= 2000
ORDER BY f.d_year, f.d_month_seq, f.i_category, f.store_name
LIMIT 200
