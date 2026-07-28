/*
Goal: Calculate yearly and carrier‑level totals of return losses and sales profit for the year 2001, including the average catalog loss per carrier, using all eight selected TPC‑DS tables. The query demonstrates complex joins, filtering, a scalar subquery with DISTINCT, a GROUP BY ROLLUP for subtotals, a HAVING clause, ordering and a LIMIT.
*/
WITH joined_data AS (
    SELECT
        d.d_year AS return_year,
        ds.d_month_seq AS sale_month_seq,
        sm.sm_carrier,
        ws.web_country,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        ss.ss_net_profit AS sales_net_profit,
        (
            SELECT AVG(DISTINCT cr2.cr_net_loss)
            FROM catalog_returns cr2
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
        ) AS avg_catalog_loss_per_carrier
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier IN ('ALLIANCE', 'MSC', 'BOXBUNDLES')
      AND ws.web_country = 'United States'
      AND ds.d_month_seq BETWEEN 1 AND 12
)
SELECT
    return_year,
    sm_carrier,
    web_country,
    SUM(catalog_net_loss)               AS total_catalog_loss,
    SUM(store_net_loss)                 AS total_store_loss,
    SUM(web_net_loss)                   AS total_web_loss,
    SUM(sales_net_profit)               AS total_sales_profit,
    SUM(catalog_net_loss + store_net_loss + web_net_loss) AS total_return_loss,
    (SUM(catalog_net_loss + store_net_loss + web_net_loss) - SUM(sales_net_profit)) AS net_position,
    AVG(avg_catalog_loss_per_carrier)   AS avg_catalog_loss_per_carrier_over_groups
FROM joined_data
GROUP BY ROLLUP (return_year, sm_carrier, web_country)
HAVING SUM(catalog_net_loss + store_net_loss + web_net_loss) > 1000
ORDER BY return_year DESC, sm_carrier, web_country
LIMIT 100
