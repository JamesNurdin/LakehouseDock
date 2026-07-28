WITH sr AS (
    SELECT *
    FROM store_returns
    WHERE sr_customer_sk IN (2275408, 8227002)
      AND sr_refunded_cash >= 60
),
hd AS (
    SELECT *
    FROM household_demographics
),
ib AS (
    SELECT *
    FROM income_band
    WHERE ib_lower_bound = 50001
),
cr AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_return_ship_cost > 100
),
cp AS (
    SELECT *
    FROM catalog_page
    WHERE cp_department = 'Electronics'
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    AVG(sr.sr_refunded_cash) AS avg_store_refunded_cash,
    MAX(cr.cr_return_amount) AS max_catalog_return_amount
FROM sr
JOIN hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN cr ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, cp.cp_department
ORDER BY total_store_net_loss DESC
LIMIT 100
