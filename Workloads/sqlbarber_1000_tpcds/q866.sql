SELECT cd.cd_gender,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
INNER JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
INNER JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
INNER JOIN (
    SELECT ws_order_number,
           ws_item_sk,
           ws_sold_date_sk
    FROM web_sales
    WHERE ws_sold_date_sk = 2452585
) ws ON ws.ws_order_number = wr.wr_order_number
WHERE cs.cs_quantity > 34
GROUP BY cd.cd_gender
HAVING cd.cd_gender = 'M'
