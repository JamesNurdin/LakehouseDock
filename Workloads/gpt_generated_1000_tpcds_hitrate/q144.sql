WITH sales_cte AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        p.p_promo_name,
        CASE WHEN ss.ss_coupon_amt > 0 THEN 'Coup' ELSE 'NoCoup' END AS coupon_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    cp.cp_catalog_page_number,
    sc.c_first_name,
    sc.c_last_name,
    sc.d_year AS sales_year,
    d_ret.d_year AS return_year,
    sc.p_promo_name,
    sc.coupon_flag,
    SUM(sc.ss_quantity) AS total_qty,
    SUM(sc.ss_net_profit) AS total_profit
FROM sales_cte sc
RIGHT JOIN catalog_page cp
    ON cp.cp_start_date_sk = sc.ss_sold_date_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = cp.cp_end_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = cp.cp_start_date_sk
    AND wp.wp_customer_sk = sc.ss_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = cp.cp_end_date_sk
    AND wr.wr_returning_customer_sk = sc.ss_customer_sk
LEFT JOIN date_dim d_ret
    ON d_ret.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = cp.cp_start_date_sk
WHERE EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_returned_date_sk = cp.cp_end_date_sk
      AND wr2.wr_returning_customer_sk = sc.ss_customer_sk
)
GROUP BY
    cp.cp_catalog_page_number,
    sc.c_first_name,
    sc.c_last_name,
    sc.d_year,
    d_ret.d_year,
    sc.p_promo_name,
    sc.coupon_flag
ORDER BY total_profit DESC
LIMIT 100
