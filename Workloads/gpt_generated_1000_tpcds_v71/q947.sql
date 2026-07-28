WITH distinct_sites AS (
    SELECT DISTINCT
        web_site_sk,
        web_name,
        web_tax_percentage
    FROM web_site
    WHERE web_tax_percentage >= 0.05
)
SELECT
    cd_bill.cd_gender,
    td.t_shift,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_quantity) AS min_qty,
    MAX(ws.ws_quantity) AS max_qty
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN distinct_sites ds
  ON ws.ws_web_site_sk = ds.web_site_sk
WHERE td.t_hour = 15
  AND td.t_shift = 'second'
  AND cd_bill.cd_credit_rating = 'Good'
  AND hd_bill.hd_vehicle_count >= 2
GROUP BY GROUPING SETS (
    (cd_bill.cd_gender, td.t_shift),
    (cd_bill.cd_gender),
    (td.t_shift),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
