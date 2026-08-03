WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cd.cd_credit_rating,
        cd.cd_dep_employed_count,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
      AND ss.ss_ext_sales_price > 100.00
      AND cd.cd_credit_rating = 'High Risk'
      AND cd.cd_dep_employed_count >= 2
      AND hd.hd_buy_potential IN ('>10000', '5001-10000')
      AND ib.ib_upper_bound <= 20000
)
SELECT
    fs.ss_ticket_number,
    fs.ss_sold_date_sk,
    COUNT(DISTINCT cr.cr_order_number) AS returned_orders_cnt,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_profit) AS avg_profit,
    MIN(fs.ss_ext_sales_price) AS min_sales,
    MAX(fs.ss_ext_sales_price) AS max_sales,
    SUM(CASE WHEN cr.cr_return_amount > 1000 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount,
    SUM(CASE WHEN wr.wr_return_amt > 500 THEN wr.wr_return_amt ELSE 0 END) AS high_web_return_amt
FROM filtered_sales fs
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = fs.ss_cdemo_sk
   AND cr.cr_refunded_hdemo_sk = fs.ss_hdemo_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = fs.ss_cdemo_sk
   AND wr.wr_refunded_hdemo_sk = fs.ss_hdemo_sk
WHERE fs.ss_ticket_number NOT IN (
        SELECT cr2.cr_order_number
        FROM catalog_returns cr2
        WHERE cr2.cr_return_ship_cost > 500.00
    )
  AND fs.ss_ticket_number IN (
        SELECT order_num FROM (
            SELECT cr3.cr_order_number AS order_num FROM catalog_returns cr3
            INTERSECT
            SELECT wr3.wr_order_number AS order_num FROM web_returns wr3
        ) AS intersect_orders
    )
GROUP BY
    fs.ss_ticket_number,
    fs.ss_sold_date_sk
HAVING COUNT(*) > 1
ORDER BY total_sales DESC
LIMIT 100
