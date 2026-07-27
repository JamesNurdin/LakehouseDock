WITH joined AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        t_ws.t_sub_shift,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_list_price,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        ws.ws_order_number,
        ca.ca_state,
        s.s_number_employees,
        wsite.web_country
    FROM web_sales ws
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c_bill.c_customer_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c_bill.c_customer_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE ib.ib_lower_bound >= 30000
      AND ib.ib_upper_bound <= 100000
      AND t_ws.t_sub_shift = 'evening'
      AND ws.ws_quantity > 1
      AND ws.ws_list_price BETWEEN 20 AND 200
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND s.s_number_employees > 100
      AND wsite.web_country = 'United States'
),
agg AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        t_sub_shift,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_loss,
        SUM(COALESCE(sr_net_loss, 0)) AS total_store_loss,
        SUM(COALESCE(wr_net_loss, 0)) AS total_web_loss,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM joined
    GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound, t_sub_shift
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    t_sub_shift,
    total_net_paid,
    total_net_profit,
    (total_catalog_loss + total_store_loss + total_web_loss) AS total_return_loss,
    (total_catalog_loss + total_store_loss + total_web_loss) / NULLIF(total_net_paid, 0) AS loss_to_sales_ratio,
    order_cnt
FROM agg
WHERE total_net_paid > 10000
  AND (total_catalog_loss + total_store_loss + total_web_loss) > 5000
ORDER BY loss_to_sales_ratio DESC
LIMIT 100
