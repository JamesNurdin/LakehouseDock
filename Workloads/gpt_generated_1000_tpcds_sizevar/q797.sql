/*
Goal: Identify the top 5 customers (by return amount) within each household buying‑potential segment, combining catalog and web return activity, while demonstrating advanced Trino features such as a pre‑aggregation CTE, a FULL OUTER JOIN, UNION DISTINCT, EXCEPT, and a ranking window function. The result is limited to the first 100 rows.
*/
WITH
  -- Pre‑aggregate catalog returns per order
  cr_agg AS (
    SELECT
      cr_order_number,
      SUM(cr_return_amount)      AS sum_return_amount,
      SUM(cr_net_loss)           AS sum_net_loss,
      COUNT(*)                   AS cnt_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2451910 AND 2452000
      AND cr_return_quantity > 1
      AND cr_return_amount > 1000
    GROUP BY cr_order_number
  ),
  -- Full outer join inventory with warehouse (keeps unmatched rows from both sides)
  inv_wh AS (
    SELECT
      w.w_warehouse_sk,
      w.w_warehouse_name,
      i.inv_item_sk,
      i.inv_quantity_on_hand
    FROM inventory i
    FULL OUTER JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
  ),
  -- Union of catalog‑side and web‑side aggregations (deduplicated)
  unioned AS (
    SELECT
      CAST('catalog' AS VARCHAR)            AS source_type,
      c.c_customer_id,
      hd.hd_buy_potential,
      ca.sum_return_amount                AS total_return_amount,
      ca.sum_net_loss                     AS total_net_loss,
      SUM(cs.cs_ext_sales_price)          AS total_sales_price
    FROM cr_agg ca
    JOIN catalog_sales cs
      ON ca.cr_order_number = cs.cs_order_number
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inv_wh iwh
      ON cs.cs_warehouse_sk = iwh.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2452000
      AND cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 5000
    GROUP BY c.c_customer_id, hd.hd_buy_potential, ca.sum_return_amount, ca.sum_net_loss

    UNION DISTINCT

    SELECT
      CAST('web' AS VARCHAR)               AS source_type,
      c.c_customer_id,
      hd.hd_buy_potential,
      SUM(wr.wr_return_amt)               AS total_return_amount,
      SUM(wr.wr_net_loss)                  AS total_net_loss,
      SUM(wr.wr_return_tax)                AS total_sales_price
    FROM web_returns wr
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2452000
      AND wr.wr_return_quantity > 1
      AND wr.wr_return_amt > 1000
    GROUP BY c.c_customer_id, hd.hd_buy_potential
  ),
  -- Remove rows where the aggregated return amount is zero (EXCEPT)
  filtered AS (
    SELECT
      source_type,
      c_customer_id,
      hd_buy_potential,
      total_return_amount,
      total_net_loss,
      total_sales_price
    FROM unioned
    EXCEPT
    SELECT
      source_type,
      c_customer_id,
      hd_buy_potential,
      total_return_amount,
      total_net_loss,
      total_sales_price
    FROM unioned
    WHERE total_return_amount = 0
  ),
  -- Rank rows within each buying‑potential group and keep the top‑k (k=5)
  ranked AS (
    SELECT
      source_type,
      c_customer_id,
      hd_buy_potential,
      total_return_amount,
      total_net_loss,
      total_sales_price,
      ROW_NUMBER() OVER (
        PARTITION BY hd_buy_potential
        ORDER BY total_return_amount DESC
      ) AS rn
    FROM filtered
  )
SELECT
  source_type,
  c_customer_id,
  hd_buy_potential,
  total_return_amount,
  total_net_loss,
  total_sales_price,
  rn
FROM ranked
WHERE rn <= 5
ORDER BY source_type, total_return_amount DESC
LIMIT 100
