WITH sales_detail AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
)
SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    cd.cd_gender,
    SUM(sd.ss_ext_sales_price) AS total_sales,
    AVG(sd.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT sd.ss_ticket_number) AS distinct_tickets,
    MIN(sd.ss_net_profit) AS min_profit,
    MAX(sd.ss_net_profit) AS max_profit
FROM sales_detail sd
JOIN date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
JOIN item i ON sd.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sd.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sd.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s ON sd.ss_store_sk = s.s_store_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 2001
  AND i.i_current_price BETWEEN 20 AND 50
  AND cd.cd_education_status = 'College'
  AND ib.ib_lower_bound >= 80000
  AND s.s_state = 'CA'
GROUP BY d.d_year, s.s_state, i.i_category, cd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
