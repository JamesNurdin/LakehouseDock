WITH high_income_hh AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= (SELECT MAX(ib_upper_bound) FROM income_band) / 2
)
SELECT
    CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
    s.s_city,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    SUM(sr.sr_net_loss) AS total_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    MIN(SUBSTRING(i.i_item_desc FROM 1 FOR 20)) AS example_desc,
    MIN(regexp_extract(i.i_item_desc, '([A-Z]+)', 1)) AS first_alpha_seq
FROM catalog_sales cs
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_sales.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND regexp_like(i.i_item_desc, '[0-9]{3}')
  AND s.s_city LIKE 'San%'
  AND hd.hd_demo_sk IN (SELECT hd_demo_sk FROM high_income_hh)
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND s2.s_state = 'CA'
    )
GROUP BY
    CONCAT(i.i_brand, '-', i.i_category),
    s.s_city
ORDER BY total_sales DESC
LIMIT 100
