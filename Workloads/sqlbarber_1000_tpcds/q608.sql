SELECT hd.hd_income_band_sk,
       cs.cs_sold_date_sk,
       SUM(cs.cs_net_paid) AS total_catalog_net_paid,
       COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
       (SELECT ws2.ws_net_paid
        FROM web_sales ws2
        LIMIT 1) AS sample_ws_net_paid
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_sold_date_sk = 2450843
  AND sr.sr_returned_date_sk BETWEEN 2451964 AND 2451547
GROUP BY hd.hd_income_band_sk, cs.cs_sold_date_sk
HAVING hd.hd_income_band_sk > 5
