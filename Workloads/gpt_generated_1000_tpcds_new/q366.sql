/* goal: Identify high‑value items sold to households with moderate buying potential, combining store and catalog sales information, and show per‑item aggregate metrics together with the total catalog net profit for the same item‑household segment. */
WITH
  store_agg AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      ss.ss_hdemo_sk AS hd_demo_sk,
      COUNT(*) AS store_txn_cnt,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      AVG(ss.ss_sales_price) AS store_avg_price
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_sales_price > 50
      AND i.i_current_price BETWEEN 20 AND 200
      AND hd.hd_income_band_sk IN (9, 10, 11)
    GROUP BY ss.ss_item_sk, ss.ss_hdemo_sk
  ),
  catalog_agg AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      cs.cs_bill_hdemo_sk AS hd_demo_sk,
      COUNT(*) AS catalog_txn_cnt,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
      AVG(cs.cs_sales_price) AS catalog_avg_price
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price > 50
      AND i.i_current_price BETWEEN 20 AND 200
      AND hd.hd_income_band_sk IN (9, 10, 11)
    GROUP BY cs.cs_item_sk, cs.cs_bill_hdemo_sk
  ),
  common_items AS (
    SELECT item_sk FROM store_agg
    INTERSECT
    SELECT item_sk FROM catalog_agg
  ),
  union_agg AS (
    SELECT
      sa.item_sk,
      sa.hd_demo_sk,
      sa.store_txn_cnt AS txn_cnt,
      sa.store_sales_total AS sales_total,
      sa.store_avg_price AS avg_price,
      'store' AS source
    FROM store_agg sa
    WHERE sa.item_sk IN (SELECT item_sk FROM common_items)

    UNION

    SELECT
      ca.item_sk,
      ca.hd_demo_sk,
      ca.catalog_txn_cnt AS txn_cnt,
      ca.catalog_sales_total AS sales_total,
      ca.catalog_avg_price AS avg_price,
      'catalog' AS source
    FROM catalog_agg ca
    WHERE ca.item_sk IN (SELECT item_sk FROM common_items)
  )
SELECT
  ua.item_sk,
  i.i_item_id,
  i.i_product_name,
  hd.hd_buy_potential,
  ua.hd_demo_sk,
  SUM(ua.txn_cnt) AS total_transactions,
  SUM(ua.sales_total) AS total_sales,
  AVG(ua.avg_price) AS avg_price_overall,
  (
    SELECT SUM(cs.cs_net_profit)
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_item_sk = ua.item_sk
      AND cs.cs_bill_hdemo_sk = ua.hd_demo_sk
  ) AS catalog_net_profit
FROM union_agg ua
JOIN tpcds.item i ON ua.item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd ON ua.hd_demo_sk = hd.hd_demo_sk
WHERE i.i_brand = 'Brand#23'
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY ua.item_sk, i.i_item_id, i.i_product_name, hd.hd_buy_potential, ua.hd_demo_sk
ORDER BY total_sales DESC
LIMIT 100
