WITH avg_income AS (
    SELECT AVG(ib_upper_bound) AS avg_upper
    FROM income_band
)
SELECT
    d.d_year,
    i.i_category,
    cd.cd_gender,
    ws.web_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    AVG(i.i_current_price) AS avg_item_price,
    (SELECT avg_upper FROM avg_income) AS avg_income_upper
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_wholesale_cost > 10
  AND hd.hd_vehicle_count >= 1
  AND r.r_reason_desc LIKE '%gift%'
GROUP BY GROUPING SETS (
    (d.d_year, i.i_category, cd.cd_gender, ws.web_name),
    (d.d_year, i.i_category, ws.web_name),
    (d.d_year, ws.web_name),
    (ws.web_name)
)
ORDER BY total_store_sales DESC
LIMIT 100
