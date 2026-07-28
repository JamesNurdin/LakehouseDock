WITH profit_by_day AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        c.c_first_name,
        c.c_last_name,
        /* total profit combines sales and subtracts returns/losses */
        COALESCE(cs.cs_net_profit, 0) 
        + COALESCE(ws.ws_net_profit, 0)
        - COALESCE(sr.sr_net_loss, 0)
        - COALESCE(cr.cr_return_amount, 0) AS total_profit
    FROM
        date_dim d
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
        LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
        LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
        LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
        LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    WHERE
        d.d_year = 2001
        AND ib.ib_lower_bound >= 80000
        AND cc.cc_company = 3
)
SELECT DISTINCT
    d_date,
    d_year,
    d_month_seq,
    ca_state,
    c_first_name,
    c_last_name,
    CASE
        WHEN total_profit > 50000 THEN 'High'
        WHEN total_profit BETWEEN 10000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM
    profit_by_day
ORDER BY
    profit_rank_year,
    total_profit DESC
LIMIT 100
