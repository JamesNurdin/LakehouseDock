WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_list_price,
        cs.cs_ship_date_sk,
        cs.cs_bill_hdemo_sk,
        wr.wr_refunded_cash,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    FULL OUTER JOIN web_returns wr
        ON cs.cs_bill_hdemo_sk = wr.wr_refunded_hdemo_sk
    LEFT JOIN household_demographics hd
        ON (cs.cs_bill_hdemo_sk = hd.hd_demo_sk OR wr.wr_refunded_hdemo_sk = hd.hd_demo_sk)
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid_inc_ship) AS total_net_paid,
    AVG(wr_refunded_cash) AS avg_refund,
    MIN(cs_ext_list_price) AS min_list_price,
    MAX(cs_ext_list_price) AS max_list_price
FROM sales_returns
WHERE cs_ship_date_sk BETWEEN 2450845 AND 2450885
  AND wr_refunded_cash > 200.00
  AND hd_dep_count >= 2
  AND EXISTS (
        SELECT 1 FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd_income_band_sk
          AND ib2.ib_lower_bound <= 30000
    )
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
UNION DISTINCT
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid_inc_ship) AS total_net_paid,
    AVG(wr_refunded_cash) AS avg_refund,
    MIN(cs_ext_list_price) AS min_list_price,
    MAX(cs_ext_list_price) AS max_list_price
FROM sales_returns
WHERE cs_ship_date_sk BETWEEN 2450900 AND 2450950
  AND wr_refunded_cash BETWEEN 50 AND 150
  AND hd_vehicle_count >= 0
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
