WITH cr_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_tax) AS total_return_tax,
        SUM(cr_fee) AS total_fee,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
    GROUP BY cr_order_number
)
SELECT
    ds.d_year,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr_agg.total_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN cr_agg ON cs.cs_order_number = cr_agg.cr_order_number
JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND dr.d_date BETWEEN DATE '2001-06-01' AND DATE '2001-06-30'
  AND sm.sm_carrier = 'DHL'
  AND w.w_zip = '44593'
  AND hd.hd_income_band_sk = 5
  AND p.p_discount_active = 'Y'
GROUP BY ds.d_year, sm.sm_type, w.w_warehouse_name, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
