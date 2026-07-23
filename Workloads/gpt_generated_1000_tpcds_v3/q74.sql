WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_paid) AS sum_net_paid,
        SUM(ss.ss_net_profit) AS sum_net_profit,
        COUNT(*) AS cnt_sales
    FROM store_sales ss
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number
)
SELECT
    d_sold.d_year AS year,
    s.s_store_name AS store_name,
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    hd.hd_buy_potential AS buy_potential,
    SUM(sales_agg.sum_net_paid) AS total_store_net_paid,
    SUM(sales_agg.sum_net_profit) AS total_store_net_profit,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_sold.d_date) AS last_sold_date
FROM sales_agg
JOIN date_dim d_sold
    ON sales_agg.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
JOIN item i
    ON sales_agg.ss_item_sk = i.i_item_sk
JOIN customer c
    ON sales_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sales_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sales_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = sales_agg.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d_sold.d_date_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2002
  AND s.s_tax_percentage >= 0.08
  AND ib.ib_lower_bound >= 50000
  AND cc.cc_hours = '8AM-4PM'
  AND i.i_color = 'Red'
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        WHERE ws.web_open_date_sk = d_sold.d_date_sk
          AND ws.web_name = 'MainSite'
    )
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    i.i_brand,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_store_net_paid DESC
LIMIT 100
