/*
  Goal: Analyze combined store and web sales for each call center in California for the year 2001, filtering for relatively high list prices, quantity, web‑sale price and return amount, then classify the sales level and rank call centers by total store sales.
*/
WITH filtered_store_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_list_price
    FROM store_sales ss
    WHERE ss.ss_list_price > 50               -- predicate 1
      AND ss.ss_quantity > 1                  -- predicate 2
),
aggregated AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        SUM(fss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        CASE
            WHEN SUM(fss.ss_ext_sales_price) > 100000 THEN 'Very High'
            WHEN SUM(fss.ss_ext_sales_price) > 50000  THEN 'High'
            ELSE 'Medium'
        END AS sales_category
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    JOIN filtered_store_sales fss ON fss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                     -- predicate 3
      AND cc.cc_state = 'CA'
      AND ws.ws_sales_price > 20
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_call_center_sk = cc.cc_call_center_sk
              AND cr.cr_returned_date_sk = d.d_date_sk
              AND cr.cr_return_amount > 100   -- predicate 4 (inside semi‑join)
        )
    GROUP BY cc.cc_call_center_id, d.d_year
)
SELECT
    cc_call_center_id,
    d_year,
    total_store_sales,
    total_web_sales,
    sales_category,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY total_store_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_store_sales DESC, sales_rank
LIMIT 100
