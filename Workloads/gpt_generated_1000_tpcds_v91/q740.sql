WITH RECURSIVE base_sales (s_store_sk, s_store_name, s_state, t_hour, total_sales, total_profit, distinct_tickets) AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        ss.ss_ext_sales_price > 1000
        AND s.s_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 18
        AND hd.hd_vehicle_count >= 2
        AND p.p_discount_active = 'Y'
        AND ss.ss_promo_sk IN (
            SELECT p2.p_promo_sk
            FROM promotion p2
            WHERE p2.p_discount_active = 'Y'
        )
        AND EXISTS (
            SELECT 1
            FROM income_band ib2
            WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
              AND ib2.ib_lower_bound > 50000
        )
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, t.t_hour
    UNION ALL
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        t_hour,
        total_sales,
        total_profit,
        distinct_tickets
    FROM base_sales
    WHERE false
),
returns_per_hour (t_hour, total_return_amount, total_return_loss) AS (
    SELECT
        t.t_hour,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    INNER JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    INNER JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    INNER JOIN income_band ib_wr ON hd_wr.hd_income_band_sk = ib_wr.ib_income_band_sk
    INNER JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    WHERE
        t.t_hour BETWEEN 9 AND 18
        AND ib_wr.ib_lower_bound > 30000
        AND ca_wr.ca_country = 'United States'
    GROUP BY t.t_hour
)
SELECT
    bs.s_store_name,
    bs.s_state,
    bs.t_hour,
    bs.total_sales,
    bs.total_profit,
    bs.distinct_tickets,
    COALESCE(rph.total_return_amount, 0) AS total_return_amount,
    (bs.total_sales - COALESCE(rph.total_return_amount, 0)) AS net_sales_after_returns
FROM base_sales bs
LEFT JOIN returns_per_hour rph ON bs.t_hour = rph.t_hour
ORDER BY bs.total_sales DESC
LIMIT 100
