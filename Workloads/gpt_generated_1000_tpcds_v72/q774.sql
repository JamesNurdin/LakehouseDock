WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        d.d_year,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 2
      AND ss.ss_sales_price > 100
)
SELECT
    d.d_date,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    cs.cs_quantity,
    cs.cs_sales_price,
    ws.ws_sales_price,
    we.web_name,
    s.s_store_name,
    sm.sm_type AS ship_type,
    CASE WHEN sb.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (PARTITION BY d.d_date ORDER BY sb.ss_net_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_customer_sk = c.c_customer_sk) AS total_returns,
    r.r_reason_desc
FROM sales_base sb
JOIN date_dim d
    ON sb.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON sb.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sb.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sb.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON sb.ss_store_sk = s.s_store_sk
JOIN time_dim t
    ON sb.ss_sold_time_sk = t.t_time_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = sb.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '5000+'
  AND ib.ib_upper_bound > 50000
ORDER BY d.d_date, profit_rank
LIMIT 100
