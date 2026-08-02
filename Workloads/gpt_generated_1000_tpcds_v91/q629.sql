WITH sales_and_returns AS (
    SELECT
        d_sales.d_year,
        s.s_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cr.cr_net_loss,
        wr.wr_net_loss,
        p.p_discount_active,
        t.t_hour
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c_sales
        ON ss.ss_customer_sk = c_sales.c_customer_sk
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN income_band ib
        ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sales.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sales.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE d_sales.d_year = 2002
      AND s.s_state = 'TX'
      AND ib.ib_lower_bound >= 50000
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        d_year,
        s_state,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(ss_ext_sales_price)                     AS total_sales,
        SUM(ss_net_profit)                          AS total_profit,
        COALESCE(SUM(cr_net_loss), 0)               AS total_catalog_return_loss,
        COALESCE(SUM(wr_net_loss), 0)               AS total_web_return_loss,
        SUM(ss_net_profit) - COALESCE(SUM(cr_net_loss), 0) - COALESCE(SUM(wr_net_loss), 0) AS total_net
    FROM sales_and_returns
    GROUP BY CUBE(d_year, s_state, ib_income_band_sk, ib_lower_bound, ib_upper_bound)
    HAVING SUM(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales)
)
SELECT
    d_year,
    s_state,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_sales,
    total_profit,
    total_catalog_return_loss,
    total_web_return_loss,
    total_net,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net DESC) AS net_profit_rank
FROM aggregated
ORDER BY d_year, net_profit_rank
LIMIT 100
