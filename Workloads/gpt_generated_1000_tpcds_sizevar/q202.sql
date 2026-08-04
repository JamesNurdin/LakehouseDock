WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        ca.ca_state AS customer_state,
        ib.ib_lower_bound,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'N'
      AND c.c_birth_country = 'JORDAN'
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND t.t_meal_time = 'dinner'
    GROUP BY d.d_year, i.i_category, s.s_state, ca.ca_state, ib.ib_lower_bound
),
web_agg AS (
    SELECT
        dw.d_year,
        i2.i_category,
        ws.ws_net_paid AS web_sales,
        ws.ws_net_profit AS web_profit
    FROM web_sales ws
    JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN time_dim tw ON ws.ws_sold_time_sk = tw.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE dw.d_year BETWEEN 1998 AND 2000
      AND i2.i_brand = 'Brand#12'
      AND p2.p_discount_active = 'N'
      AND c2.c_birth_country = 'JORDAN'
      AND ca2.ca_state = 'CA'
      AND we.web_state = 'CA'
),
final AS (
    SELECT
        sa.d_year,
        sa.i_category,
        sa.s_state,
        sa.customer_state,
        sa.total_sales,
        sa.total_profit,
        sa.total_return_amt,
        (sa.total_sales - sa.total_return_amt) AS net_sales,
        CASE
            WHEN sa.total_profit / NULLIF(sa.total_sales, 0) > 0.2 THEN 'High'
            ELSE 'Low'
        END AS profit_level,
        wa.web_sales,
        wa.web_profit
    FROM sales_agg sa
    LEFT JOIN web_agg wa
        ON sa.d_year = wa.d_year
        AND sa.i_category = wa.i_category
)
SELECT
    d_year,
    i_category,
    s_state,
    profit_level,
    SUM(net_sales) AS sum_net_sales,
    SUM(total_profit) AS sum_total_profit,
    SUM(web_sales) AS sum_web_sales,
    SUM(web_profit) AS sum_web_profit
FROM final
GROUP BY d_year, i_category, s_state, profit_level
HAVING SUM(net_sales) > 100000
ORDER BY sum_net_sales DESC
LIMIT 100
