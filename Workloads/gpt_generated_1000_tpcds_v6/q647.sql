WITH base AS (
  SELECT
    w.w_warehouse_name,
    w.w_state,
    i.i_brand,
    i.i_brand_id,
    i.i_current_price,
    cs.cs_net_paid,
    ss.ss_net_paid,
    cs.cs_order_number,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    r.r_reason_desc
  FROM catalog_sales cs
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
  JOIN promotion p2
    ON ss.ss_promo_sk = p2.p_promo_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_refund
    ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  WHERE
    i.i_brand_id IN (1001001, 2004002)
    AND i.i_current_price < 5.00
    AND p.p_channel_demo = 'N'
    AND w.w_state = 'CA'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND wr.wr_return_quantity > 0
),
agg AS (
  SELECT
    w_warehouse_name,
    w_state,
    i_brand,
    i_brand_id,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
    AVG(wr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN r_reason_desc = 'Customer not satisfied' THEN wr_return_amt ELSE 0 END) AS unsat_return_amount,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand_id = i_brand_id) AS max_price_for_brand
  FROM base
  GROUP BY
    w_warehouse_name,
    w_state,
    i_brand,
    i_brand_id
)
SELECT
  w_warehouse_name,
  w_state,
  i_brand,
  i_brand_id,
  total_catalog_sales,
  total_store_sales,
  catalog_order_cnt,
  avg_return_amount,
  unsat_return_amount,
  max_price_for_brand,
  SUM(total_catalog_sales) OVER (PARTITION BY w_state ORDER BY total_catalog_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_catalog_sales_by_state
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
