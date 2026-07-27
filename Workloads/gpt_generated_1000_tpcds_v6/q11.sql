WITH cs_h AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_list_price,
        cs.cs_ext_discount_amt,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_list_price BETWEEN 100 AND 200
      AND cs.cs_ext_discount_amt > 0
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND hd.hd_income_band_sk = 11
      AND hd.hd_buy_potential = '>10000'
)
SELECT
    hd_buy_potential,
    CASE WHEN cs_ext_sales_price > 2000 THEN 'High' ELSE 'Low' END AS sales_category,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_profit) AS total_profit,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity
FROM cs_h
LEFT JOIN web_returns wr
  ON cs_h.cs_order_number = wr.wr_order_number
  AND wr.wr_returned_date_sk = 2451767
  AND wr.wr_return_amt > 50
GROUP BY
    hd_buy_potential,
    CASE WHEN cs_ext_sales_price > 2000 THEN 'High' ELSE 'Low' END
ORDER BY total_profit DESC
LIMIT 100
