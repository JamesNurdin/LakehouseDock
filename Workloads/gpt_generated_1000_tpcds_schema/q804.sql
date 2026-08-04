WITH
  /* Base query that joins all nine tables using only the allowed relationships */
  base AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      cd.cd_demo_sk,
      cd.cd_gender,
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      i.i_item_sk,
      i.i_item_id,
      i.i_current_price,
      inv.inv_quantity_on_hand,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      ws.ws_ext_ship_cost,
      ws.ws_net_paid,
      wp.wp_char_count
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.item i
      ON 1 = 1                       -- placeholder, will be linked by other joins
    JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ib.ib_lower_bound >= 100000                     -- realistic filter 1
      AND hd.hd_buy_potential = '501-1000'                -- realistic filter 2
      AND i.i_current_price BETWEEN 10 AND 100           -- realistic filter 3
      AND sr.sr_return_quantity > 1                     -- realistic filter 4
      AND ws.ws_ext_ship_cost > 500.00                   -- realistic filter 5
      AND wp.wp_char_count > 2000                        -- realistic filter 6
  ),

  /* Keys that appear in sales (through the base CTE) */
  items_in_sales AS (
    SELECT DISTINCT i_item_sk AS item_sk FROM base
  ),

  /* Keys that appear in returns (independent of the base) */
  items_in_returns AS (
    SELECT DISTINCT sr.sr_item_sk AS item_sk
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 1
  ),

  /* Intersection of the two key sets */
  intersect_items AS (
    SELECT item_sk FROM items_in_sales
    INTERSECT
    SELECT item_sk FROM items_in_returns
  ),

  /* Items sold but never returned */
  except_items AS (
    SELECT item_sk FROM items_in_sales
    EXCEPT
    SELECT item_sk FROM items_in_returns
  ),

  /* Small dimension cross‑joined with a computed set (VALUES) */
  cross_joined AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           v.grp
    FROM tpcds.income_band ib
    CROSS JOIN (VALUES (1), (2), (3)) AS v (grp)
    WHERE ib.ib_lower_bound >= 100000
  ),

  /* Aggregation per income band and buying potential */
  agg AS (
    SELECT
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      hd.hd_buy_potential,
      COUNT(DISTINCT c.c_customer_sk)                         AS num_customers,
      SUM(sr.sr_return_amt)                                 AS total_return_amount,
      SUM(ws.ws_net_paid)                                   AS total_sales_amount,
      AVG(i.i_current_price)                                 AS avg_item_price,
      MIN(i.i_current_price)                                 AS min_item_price,
      MAX(i.i_current_price)                                 AS max_item_price,
      COUNT(DISTINCT intersect_items.item_sk)                AS num_items_both_sales_and_returns,
      COUNT(DISTINCT except_items.item_sk)                   AS num_items_sales_not_returns
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.item i
      ON i.i_item_sk = i.i_item_sk               -- dummy join to bring the table into scope
    JOIN tpcds.store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN intersect_items
      ON i.i_item_sk = intersect_items.item_sk
    LEFT JOIN except_items
      ON i.i_item_sk = except_items.item_sk
    WHERE ib.ib_lower_bound >= 100000
      AND hd.hd_buy_potential = '501-1000'
      AND i.i_current_price BETWEEN 10 AND 100
      AND sr.sr_return_quantity > 1
      AND ws.ws_ext_ship_cost > 500.00
      AND ws.ws_ext_ship_cost IS NOT NULL
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, hd.hd_buy_potential
  )

SELECT
  a.ib_income_band_sk,
  a.ib_lower_bound,
  a.hd_buy_potential,
  a.num_customers,
  a.total_return_amount,
  a.total_sales_amount,
  a.avg_item_price,
  a.min_item_price,
  a.max_item_price,
  a.num_items_both_sales_and_returns,
  a.num_items_sales_not_returns,
  LAG(a.total_sales_amount) OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.hd_buy_potential) AS lag_total_sales_amount,
  cj.grp AS cross_join_group
FROM agg a
CROSS JOIN cross_joined cj
ORDER BY a.total_sales_amount DESC
LIMIT 100
