WITH daily_metrics AS (
    SELECT
        d.d_date,
        d.d_year,
        hd.hd_income_band_sk,
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_count
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2002
        AND hd.hd_income_band_sk BETWEEN 10 AND 15
        AND i.inv_quantity_on_hand > 0
        AND c.c_preferred_cust_flag = 'Y'
        AND ss.ss_ext_tax > 0
    GROUP BY
        d.d_date,
        d.d_year,
        hd.hd_income_band_sk,
        c.c_customer_sk
)
SELECT
    dm.d_year,
    dm.hd_income_band_sk,
    SUM(dm.total_store_profit) AS sum_store_profit,
    SUM(dm.total_store_return_loss) AS sum_store_return_loss,
    SUM(dm.total_web_return_loss) AS sum_web_return_loss,
    SUM(dm.total_inventory_qty) AS sum_inventory_qty,
    SUM(dm.web_page_count) AS total_web_pages,
    (SUM(dm.total_store_profit) - SUM(dm.total_store_return_loss) - SUM(dm.total_web_return_loss)) AS net_profit_adj,
    CASE
        WHEN (SUM(dm.total_store_profit) - SUM(dm.total_store_return_loss) - SUM(dm.total_web_return_loss)) > 500000 THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM daily_metrics dm
GROUP BY
    dm.d_year,
    dm.hd_income_band_sk
HAVING
    SUM(dm.total_store_profit) > 1000000
ORDER BY net_profit_adj DESC
LIMIT 100
