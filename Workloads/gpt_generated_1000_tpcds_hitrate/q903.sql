WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cs.cs_net_paid > (
          SELECT MAX(cs2.cs_net_paid)
          FROM catalog_sales cs2
          WHERE cs2.cs_quantity > 1
      )
      AND cs.cs_item_sk IN (
          SELECT i.i_item_sk
          FROM item i
          WHERE i.i_brand = 'BrandX'
      )
)
SELECT
    ROW_NUMBER() OVER (ORDER BY hd.hd_demo_sk) AS row_num,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    i.i_item_sk,
    i.i_color,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    MAX(CASE WHEN wr.wr_fee > 30 THEN wr.wr_fee ELSE NULL END) AS max_high_fee,
    MIN(CASE WHEN i.i_rec_end_date > DATE '2000-01-01' THEN i.i_rec_end_date ELSE NULL END) AS earliest_rec_end
FROM filtered_sales fs
RIGHT OUTER JOIN household_demographics hd
    ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i
    ON fs.cs_item_sk = i.i_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_color IN ('rosy', 'purple')
  AND hd.hd_vehicle_count >= 0
  AND (wr.wr_fee IS NULL OR wr.wr_fee > 20)
GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count, i.i_item_sk, i.i_color
ORDER BY total_sales DESC
LIMIT 100
