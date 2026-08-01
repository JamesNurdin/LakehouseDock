WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        t.t_time,
        t.t_hour,
        t.t_meal_time,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        ca.ca_city
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        t.t_hour BETWEEN 12 AND 14
        AND hd.hd_vehicle_count > 0
        AND ib.ib_upper_bound <= 120000
        AND s.s_state = 'CA'
)
SELECT
    sd.s_store_name,
    sd.i_category,
    sd.t_meal_time,
    COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
    SUM(sd.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(sd.i_current_price) AS avg_item_price,
    MAX(sr.sr_return_amt) AS max_return_amt,
    SUM(CASE WHEN sr.sr_return_amt > 500 THEN 1 ELSE 0 END) AS large_return_count
FROM sales_data sd
INNER JOIN store_returns sr ON sr.sr_ticket_number = sd.ss_ticket_number
    AND sr.sr_item_sk = sd.ss_item_sk
    AND sr.sr_store_sk = sd.ss_store_sk
    AND sr.sr_customer_sk = sd.ss_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_sk = sr.sr_reason_sk
      AND r.r_reason_desc = 'Damaged'
)
GROUP BY
    sd.s_store_name,
    sd.i_category,
    sd.t_meal_time
ORDER BY total_sales DESC
LIMIT 100
