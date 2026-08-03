WITH joined AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_list_price,
    ss.ss_ext_sales_price,
    ss.ss_ext_wholesale_cost,
    ss.ss_coupon_amt,
    ss.ss_customer_sk,
    sr.sr_customer_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_return_ship_cost,
    sr.sr_store_credit,
    sr.sr_reversed_charge,
    sr.sr_net_loss,
    sr.sr_store_sk
  FROM tpcds.store_sales ss
  FULL OUTER JOIN tpcds.store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
  WHERE
    ss.ss_list_price BETWEEN 20.00 AND 120.00
    AND ss.ss_coupon_amt < 500.00
    AND ss.ss_ext_wholesale_cost > 3000.00
    AND sr.sr_store_credit BETWEEN 1.00 AND 500.00
    AND sr.sr_return_ship_cost BETWEEN 10.00 AND 3000.00
),
high_stores AS (
  SELECT ss_store_sk
  FROM joined
  WHERE sr_return_amt > 300.00
  GROUP BY ss_store_sk
),
low_stores AS (
  SELECT ss_store_sk
  FROM joined
  WHERE sr_return_amt <= 300.00 OR sr_return_amt IS NULL
  GROUP BY ss_store_sk
),
target_stores AS (
  SELECT ss_store_sk FROM high_stores
  EXCEPT
  SELECT ss_store_sk FROM low_stores
),
filtered AS (
  SELECT *
  FROM joined j
  WHERE EXISTS (
    SELECT 1
    FROM tpcds.store_returns r
    WHERE r.sr_customer_sk = j.sr_customer_sk
      AND r.sr_return_amt > 200.00
  )
),
item_agg AS (
  SELECT
    f.ss_store_sk,
    f.ss_item_sk,
    SUM(COALESCE(f.sr_return_amt, 0)) AS item_return_total,
    SUM(COALESCE(f.ss_ext_sales_price, 0)) AS item_sales_total,
    COUNT(DISTINCT f.ss_ticket_number) AS ticket_cnt
  FROM filtered f
  GROUP BY f.ss_store_sk, f.ss_item_sk
),
ranked AS (
  SELECT
    i.*,
    ROW_NUMBER() OVER (PARTITION BY i.ss_store_sk ORDER BY i.item_return_total DESC) AS rn
  FROM item_agg i
)
SELECT
  r.ss_store_sk,
  r.ss_item_sk,
  r.item_return_total,
  r.item_sales_total,
  r.ticket_cnt,
  r.rn
FROM ranked r
JOIN target_stores ts ON r.ss_store_sk = ts.ss_store_sk
WHERE r.rn <= 5
  AND EXISTS (
    SELECT 1
    FROM tpcds.store_returns r2
    WHERE r2.sr_store_sk = r.ss_store_sk
      AND r2.sr_net_loss > 0
  )
ORDER BY r.item_return_total DESC
LIMIT 100
