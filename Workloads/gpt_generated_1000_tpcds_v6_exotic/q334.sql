WITH combined AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS sum_store_profit,
        SUM(cs.cs_net_profit) AS sum_catalog_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS sum_store_return_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS sum_catalog_return_loss,
        AVG(ib.ib_upper_bound) AS avg_income_upper
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50001
      AND ss.ss_net_profit > 0
      AND cs.cs_net_profit > 0
      AND ws.web_state = 'CA'
    GROUP BY s.s_store_id, d.d_year
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    c.s_store_id,
    c.d_year,
    c.sum_store_profit,
    c.sum_catalog_profit,
    (c.sum_store_profit + c.sum_catalog_profit - c.sum_store_return_loss - c.sum_catalog_return_loss) AS net_total_profit,
    c.avg_income_upper
FROM combined c
ORDER BY net_total_profit DESC
LIMIT 100
