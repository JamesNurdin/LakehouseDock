WITH sales_agg AS (
   SELECT
        cs_item_sk,
        cs_order_number,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        SUM(cs_ext_sales_price) AS total_ext_sales,
        COUNT(*) AS sales_cnt,
        AVG(cs_quantity) AS avg_quantity
   FROM catalog_sales
   WHERE cs_sold_date_sk BETWEEN 2452000 AND 2452600
     AND cs_call_center_sk = 37
   GROUP BY cs_item_sk, cs_order_number, cs_bill_hdemo_sk, cs_bill_addr_sk
)
SELECT
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(DISTINCT sa.cs_order_number) AS num_orders,
    SUM(sa.total_ext_sales) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(CASE WHEN hd.hd_dep_count = 0 THEN 1 ELSE 0 END) AS zero_dep_households,
    AVG(sa.avg_quantity) AS avg_quantity_per_sale
FROM sales_agg sa
JOIN household_demographics hd
    ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON sa.cs_bill_addr_sk = ca.ca_address_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = sa.cs_item_sk
   AND cr.cr_order_number = sa.cs_order_number
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_refunded_addr_sk = ca.ca_address_sk
   AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_quantity > 1
  AND ib.ib_lower_bound >= 30000
  AND hd.hd_dep_count <= 3
  AND ca.ca_state = 'CA'
  AND sr.sr_returned_date_sk BETWEEN 2452200 AND 2452400
GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
