/*
  Goal: Produce a comprehensive profitability view per item manufacturer, combining catalog sales, store returns and web returns. The query aggregates net amounts, applies extensive filters, ranks manufacturers, computes a per‑item average profit (via a LATERAL scalar subquery), counts high‑quantity orders, uses a FULL OUTER JOIN to keep items that appear only in sales or only in returns, intersects the item keys that exist in both catalog_sales and store_returns, and generates subtotals and a grand total with GROUP BY ROLLUP.
*/
WITH
  cs_agg AS (
    SELECT
      cs_item_sk,
      cs_bill_customer_sk,
      cs_bill_hdemo_sk,
      cs_promo_sk,
      SUM(cs_net_profit)          AS total_sales_profit,
      SUM(cs_quantity)           AS total_sales_qty
    FROM tpcds.catalog_sales
    GROUP BY cs_item_sk, cs_bill_customer_sk, cs_bill_hdemo_sk, cs_promo_sk
  ),
  sr_agg AS (
    SELECT
      sr_item_sk,
      sr_store_sk,
      sr_customer_sk,
      sr_hdemo_sk,
      SUM(sr_return_amt)         AS total_return_amount,
      SUM(sr_return_quantity)    AS total_return_qty
    FROM tpcds.store_returns
    GROUP BY sr_item_sk, sr_store_sk, sr_customer_sk, sr_hdemo_sk
  ),
  wr_agg AS (
    SELECT
      wr_item_sk,
      wr_refunded_customer_sk,
      wr_refunded_hdemo_sk,
      SUM(wr_return_amt)         AS total_web_return_amount,
      SUM(wr_return_quantity)    AS total_web_return_qty
    FROM tpcds.web_returns
    GROUP BY wr_item_sk, wr_refunded_customer_sk, wr_refunded_hdemo_sk
  ),
  /* intersect the set of items that appear in both sales and store returns */
  items_common AS (
    SELECT cs_item_sk AS item_sk FROM tpcds.catalog_sales
    INTERSECT
    SELECT sr_item_sk      FROM tpcds.store_returns
  )
SELECT
  i_manufact,
  hd_buy_potential,
  s_state,
  p_channel_email,
  net_amount,
  avg_profit_last_3_months,
  high_qty_orders,
  RANK() OVER (ORDER BY net_amount DESC) AS manufacturer_rank
FROM (
  SELECT
    i.i_manufact                                 AS i_manufact,
    hd.hd_buy_potential                         AS hd_buy_potential,
    s.s_state                                   AS s_state,
    p.p_channel_email                           AS p_channel_email,
    SUM(COALESCE(cs.total_sales_profit, 0) -
        COALESCE(sr.total_return_amount, 0) -
        COALESCE(wr.total_web_return_amount, 0)) AS net_amount,
    la.avg_profit_last_3_months,
    ho.high_qty_orders
  FROM items_common ic
  JOIN tpcds.item i
    ON ic.item_sk = i.i_item_sk
  FULL OUTER JOIN cs_agg cs
    ON i.i_item_sk = cs.cs_item_sk
  FULL OUTER JOIN sr_agg sr
    ON i.i_item_sk = sr.sr_item_sk
  FULL OUTER JOIN wr_agg wr
    ON i.i_item_sk = wr.wr_item_sk
  LEFT JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  /* LATERAL subquery: average profit for the item */
  LEFT JOIN LATERAL (
    SELECT AVG(cs2.cs_net_profit) AS avg_profit_last_3_months
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_item_sk = i.i_item_sk
  ) la ON TRUE
  /* LATERAL subquery: count of high‑quantity orders for the item */
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS high_qty_orders
    FROM tpcds.catalog_sales cs3
    WHERE cs3.cs_item_sk = i.i_item_sk
      AND cs3.cs_quantity > 5
  ) ho ON TRUE
  WHERE
    i.i_rec_start_date >= DATE '1999-01-01'               -- predicate 1
    AND p.p_cost > 500                                    -- predicate 2
    AND s.s_state = 'CA'                                  -- predicate 3
    AND hd.hd_income_band_sk BETWEEN 5 AND 10             -- predicate 4
    AND c.c_preferred_cust_flag = 'Y'                     -- predicate 5
    AND wp.wp_type = 'content'                            -- predicate 6
    AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
        )
  GROUP BY ROLLUP (
    i.i_manufact,
    hd.hd_buy_potential,
    s.s_state,
    p.p_channel_email,
    la.avg_profit_last_3_months,
    ho.high_qty_orders
  )
) agg
