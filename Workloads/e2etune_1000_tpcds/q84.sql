WITH inv_agg AS (
    SELECT inv_date_sk,
           AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
wp_agg AS (
    SELECT wp_creation_date_sk,
           COUNT(DISTINCT wp_web_page_sk) AS pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
)
SELECT
    d.d_year AS year,
    ib.ib_income_band_sk AS income_band_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    AVG(inv_agg.avg_qty_on_hand) AS avg_inventory_on_hand,
    SUM(wp_agg.pages_created) AS total_pages_created
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
LEFT JOIN wp_agg ON wp_agg.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
