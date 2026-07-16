WITH sales_agg AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           SUM(s.net_paid) AS total_sales,
           SUM(s.net_profit) AS total_profit,
           COUNT(DISTINCT CASE WHEN s.call_center_sk IS NOT NULL THEN s.call_center_sk END) AS cnt_call_center,
           COUNT(DISTINCT CASE WHEN s.store_sk IS NOT NULL THEN s.store_sk END) AS cnt_store,
           COUNT(DISTINCT CASE WHEN s.web_page_sk IS NOT NULL THEN s.web_page_sk END) AS cnt_web_page
    FROM (
        SELECT cs.cs_sold_date_sk AS date_sk,
               cs.cs_item_sk AS item_sk,
               cs.cs_net_paid AS net_paid,
               cs.cs_net_profit AS net_profit,
               cs.cs_call_center_sk AS call_center_sk,
               CAST(NULL AS integer) AS store_sk,
               CAST(NULL AS integer) AS web_page_sk
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_sold_date_sk,
               ss.ss_item_sk,
               ss.ss_net_paid,
               ss.ss_net_profit,
               CAST(NULL AS integer),
               ss.ss_store_sk,
               CAST(NULL AS integer)
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_sold_date_sk,
               ws.ws_item_sk,
               ws.ws_net_paid,
               ws.ws_net_profit,
               CAST(NULL AS integer),
               CAST(NULL AS integer),
               ws.ws_web_page_sk
        FROM web_sales ws
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), returns_agg AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           SUM(r.return_amt) AS total_return,
           SUM(r.net_loss) AS total_return_loss
    FROM (
        SELECT cr.cr_returned_date_sk AS date_sk,
               cr.cr_item_sk AS item_sk,
               cr.cr_return_amount AS return_amt,
               cr.cr_net_loss AS net_loss,
               cr.cr_call_center_sk AS call_center_sk,
               CAST(NULL AS integer) AS store_sk,
               CAST(NULL AS integer) AS web_page_sk
        FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_returned_date_sk,
               sr.sr_item_sk,
               sr.sr_return_amt,
               sr.sr_net_loss,
               CAST(NULL AS integer),
               sr.sr_store_sk,
               CAST(NULL AS integer)
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_amt,
               wr.wr_net_loss,
               CAST(NULL AS integer),
               CAST(NULL AS integer),
               wr.wr_web_page_sk
        FROM web_returns wr
    ) r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT COALESCE(s.d_year, r.d_year) AS year,
       COALESCE(s.i_category, r.i_category) AS category,
       COALESCE(s.total_sales, 0) - COALESCE(r.total_return, 0) AS net_sales,
       COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
       COALESCE(s.cnt_call_center, 0) AS cnt_call_center,
       COALESCE(s.cnt_store, 0) AS cnt_store,
       COALESCE(s.cnt_web_page, 0) AS cnt_web_page
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.d_year = r.d_year AND s.i_category = r.i_category
WHERE COALESCE(s.d_year, r.d_year) BETWEEN 1999 AND 2002
ORDER BY net_sales DESC
LIMIT 20
