WITH ss_sr AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reason_sk
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_customer_sk = sr.sr_customer_sk
        AND ss.ss_hdemo_sk = sr.sr_hdemo_sk
        AND ss.ss_store_sk = sr.sr_store_sk
)
SELECT
    d.d_year,
    s.s_state,
    ib.ib_income_band_sk,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ss_sr.ss_ext_sales_price) AS total_sales,
    SUM(ss_sr.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN ss_sr.ss_net_profit > 0 THEN ss_sr.ss_net_profit ELSE 0 END) AS total_positive_profit,
    SUM(CASE WHEN ss_sr.ss_net_profit <= 0 THEN ss_sr.ss_net_profit ELSE 0 END) AS total_negative_profit,
    SUM(COALESCE(ss_sr.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(*) AS total_transactions
FROM ss_sr
JOIN date_dim d
    ON ss_sr.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss_sr.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss_sr.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ss_sr.ss_store_sk = s.s_store_sk
LEFT JOIN reason r
    ON ss_sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
    AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND c.c_preferred_cust_flag = 'Y'
  AND ib.ib_lower_bound >= 60000
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_type = 'product'
          AND wp.wp_creation_date_sk = d.d_date_sk
    )
GROUP BY d.d_year, s.s_state, ib.ib_income_band_sk
ORDER BY total_sales DESC
LIMIT 100
