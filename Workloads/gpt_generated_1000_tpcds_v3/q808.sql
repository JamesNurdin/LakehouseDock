WITH combined_sales AS (
    SELECT
        i.i_category AS category,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cd.cd_purchase_estimate > 2000
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND inv.inv_quantity_on_hand > 0
      AND cs.cs_quantity > 1
    UNION ALL
    SELECT
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cd.cd_purchase_estimate > 2000
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND inv.inv_quantity_on_hand > 0
      AND ws.ws_quantity > 1
)
SELECT
    cs.category,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.sales) AS total_sales,
    SUM(cs.profit) AS total_profit,
    CASE WHEN SUM(cs.profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    (SELECT AVG(profit) FROM combined_sales) AS avg_profit_across_all
FROM combined_sales cs
GROUP BY cs.category
HAVING SUM(cs.sales) > 10000
ORDER BY total_sales DESC
