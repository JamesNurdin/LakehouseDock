WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(cs_quantity) AS sum_cs_quantity
    FROM catalog_sales
    WHERE cs_net_paid > 1000
      AND cs_quantity > 1
    GROUP BY cs_item_sk, cs_sold_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    SUM(ca.sum_cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM cs_agg ca
JOIN date_dim d
    ON ca.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON ca.cs_item_sk = i.i_item_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
GROUP BY d.d_year, i.i_category
HAVING SUM(ca.sum_cs_net_paid) > 5000
ORDER BY total_catalog_sales DESC
LIMIT 100
