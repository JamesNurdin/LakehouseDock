/*
Goal: Rank stores by net profit for the year 2001 while comparing total sales and total returns. The query filters on store state, income‑band upper bound, return reason, catalog page type, and only includes catalog pages belonging to the ‘Electronics’ department. It classifies each store‑year as Profit or Loss and uses RANK and ROW_NUMBER window functions.
*/
WITH sales_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d1.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) AS net_profit,
        CASE WHEN SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory i ON i.inv_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound > 80000
      AND r.r_reason_desc NOT LIKE '%defect%'
      AND cp.cp_type = 'promo'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp2.cp_department = 'Electronics'
      )
    GROUP BY s.s_store_sk, s.s_store_name, d1.d_year
)
SELECT
    s_store_sk,
    s_store_name,
    d_year,
    total_sales,
    total_returns,
    net_profit,
    profit_flag,
    RANK() OVER (ORDER BY net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit DESC) AS row_num_year
FROM sales_returns
ORDER BY net_profit DESC
LIMIT 100
