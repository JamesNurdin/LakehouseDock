WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_list_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_list_price > 2000
      AND cs.cs_quantity > 2
      AND cs.cs_sold_time_sk IN (66569, 39537)
)
SELECT
    w.w_warehouse_name,
    cd.cd_gender,
    td.t_hour,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt
FROM filtered_sales fs
JOIN time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
JOIN warehouse w
    ON fs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
   AND sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
   AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_education_status = 'Advanced Degree'
  AND td.t_second BETWEEN 5 AND 17
  AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = fs.cs_item_sk
          AND sr2.sr_return_amt > 0
    )
GROUP BY w.w_warehouse_name, cd.cd_gender, td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
