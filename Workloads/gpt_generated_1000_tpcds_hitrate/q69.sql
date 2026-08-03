WITH sales_agg AS (
    SELECT
        st.s_city,
        st.s_state,
        d_sold.d_year AS d_year,
        sm.sm_type AS sm_type,
        ib.ib_lower_bound AS income_lower,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d_sold          ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship          ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust_bill       ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_address addr_bill ON ws.ws_bill_addr_sk = addr_bill.ca_address_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib           ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer cust_ship       ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_address addr_ship ON ws.ws_ship_addr_sk = addr_ship.ca_address_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite           ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store st            ON st.s_closed_date_sk = d_ship.d_date_sk
    LEFT JOIN web_returns wr     ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r            ON r.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND st.s_state = 'GA'
      AND ib.ib_lower_bound >= 40000
      AND sm.sm_type = 'AIR'
      AND wp.wp_char_count > 5000
      AND wsite.web_country = 'United States'
      AND EXISTS (
            SELECT 1
            FROM web_returns wr2
            JOIN reason r2 ON r2.r_reason_sk = wr2.wr_reason_sk
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND r2.r_reason_desc = 'Customer Not Satisfied'
      )
    GROUP BY
        st.s_city,
        st.s_state,
        d_sold.d_year,
        sm.sm_type,
        ib.ib_lower_bound
)
SELECT
    s_city,
    s_state,
    d_year,
    sm_type,
    income_lower,
    total_profit,
    RANK() OVER (PARTITION BY s_city ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
