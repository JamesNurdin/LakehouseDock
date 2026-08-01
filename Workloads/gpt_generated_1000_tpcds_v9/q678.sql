/*
Goal: Compute daily net profit per gender and call center, rank the days by profit, and filter for high‑sales days in 2001. The query joins all nine selected tables using only the allowed join keys, applies multiple filter predicates, uses a CASE expression to label profit status, includes a correlated scalar subquery for the maximum tax rate on the day, filters groups with HAVING, ranks results with a window function, and limits the output to the top 100 days.
*/
WITH daily_metrics AS (
    SELECT
        d.d_date,
        cd.cd_gender,
        cc.cc_call_center_id,
        SUM(ss.ss_net_paid)                         AS total_store_sales,
        SUM(cs.cs_net_paid)                         AS total_catalog_sales,
        SUM(sr.sr_net_loss)                         AS total_store_returns_loss,
        SUM(cr.cr_net_loss)                         AS total_catalog_returns_loss,
        SUM(wr.wr_net_loss)                         AS total_web_returns_loss,
        SUM(i.inv_quantity_on_hand)                 AS total_inventory_quantity
    FROM date_dim d
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    WHERE d.d_date >= DATE '2001-01-01'               -- filter 1: date range start
      AND d.d_year = 2001                           -- filter 2: specific year
      AND d.d_weekend = 'N'                         -- filter 3: only weekdays
      AND ss.ss_quantity > 5                        -- filter 4: minimum store‑sales quantity
      AND i.inv_quantity_on_hand > 0                -- filter 5: inventory must be positive
      AND cc.cc_gmt_offset > 0                      -- filter 6: call center offset positive
    GROUP BY d.d_date, cd.cd_gender, cc.cc_call_center_id
    HAVING SUM(ss.ss_net_paid) > 10000               -- filter groups with high sales
)
SELECT
    dm.d_date,
    dm.cd_gender,
    dm.cc_call_center_id,
    dm.total_store_sales,
    dm.total_catalog_sales,
    dm.total_store_returns_loss,
    dm.total_catalog_returns_loss,
    dm.total_web_returns_loss,
    dm.total_inventory_quantity,
    (dm.total_store_sales + dm.total_catalog_sales - dm.total_store_returns_loss - dm.total_catalog_returns_loss - dm.total_web_returns_loss) AS net_total,
    CASE
        WHEN (dm.total_store_sales + dm.total_catalog_sales - dm.total_store_returns_loss - dm.total_catalog_returns_loss - dm.total_web_returns_loss) >= 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status,
    (SELECT MAX(cc2.cc_tax_percentage)
       FROM call_center cc2
      WHERE cc2.cc_closed_date_sk = d2.d_date_sk) AS max_tax_percentage,
    RANK() OVER (ORDER BY (dm.total_store_sales + dm.total_catalog_sales - dm.total_store_returns_loss - dm.total_catalog_returns_loss - dm.total_web_returns_loss) DESC) AS profit_rank
FROM daily_metrics dm
JOIN date_dim d2 ON d2.d_date = dm.d_date
WHERE EXISTS (
        SELECT 1
          FROM inventory inv2
         WHERE inv2.inv_date_sk = d2.d_date_sk
           AND inv2.inv_quantity_on_hand > 1000
    )
ORDER BY profit_rank
LIMIT 100
