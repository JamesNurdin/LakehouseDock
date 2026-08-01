WITH sales_returns AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        r.r_reason_desc,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit_amount,
        COALESCE(sr.sr_return_amt, 0) AS store_return_amount,
        COALESCE(wr.wr_return_amt, 0) AS web_return_amount,
        COALESCE(sr.sr_net_loss, 0) AS store_net_loss,
        COALESCE(wr.wr_net_loss, 0) AS web_net_loss,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON d.d_date_sk = wr.wr_returned_date_sk
        AND c.c_customer_sk = wr.wr_refunded_customer_sk
        AND hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    SUM(sales_amount) AS total_sales,
    SUM(store_return_amount + web_return_amount) AS total_returns,
    SUM(profit_amount) AS total_profit,
    SUM(store_net_loss + web_net_loss) AS total_loss,
    GROUPING(s_store_name) AS grp_store,
    GROUPING(d_year) AS grp_year,
    GROUPING(p_promo_name) AS grp_promo
FROM sales_returns
GROUP BY GROUPING SETS (
    (s_store_name, d_year, p_promo_name),
    (s_store_name, d_year),
    (s_store_name),
    ()
)
HAVING SUM(sales_amount) > 10000
ORDER BY total_sales DESC
LIMIT 100
