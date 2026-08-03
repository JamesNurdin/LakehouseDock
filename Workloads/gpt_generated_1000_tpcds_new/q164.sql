WITH
  sales_agg AS (
    SELECT
      cs.cs_bill_customer_sk AS cust_sk,
      cs.cs_sold_date_sk       AS sold_date_sk,
      cs.cs_item_sk            AS item_sk,
      SUM(cs.cs_net_profit)    AS total_profit,
      COUNT(*)                 AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_date_sk, cs.cs_item_sk
  ),
  returns_agg AS (
    SELECT
      sr.sr_customer_sk      AS cust_sk,
      sr.sr_returned_date_sk AS return_date_sk,
      sr.sr_item_sk          AS item_sk,
      SUM(sr.sr_refunded_cash) AS total_refund,
      COUNT(*)                 AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk, sr.sr_item_sk
  )
SELECT * FROM (
  SELECT
    c.c_customer_id,
    d.d_fy_year,
    hd.hd_income_band_sk,
    sa.total_profit,
    ra.total_refund,
    (
      SELECT SUM(inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = sa.item_sk
        AND inv.inv_date_sk = sa.sold_date_sk
    ) AS inventory_on_sale_date
  FROM sales_agg sa
  JOIN returns_agg ra ON ra.cust_sk = sa.cust_sk AND ra.item_sk = sa.item_sk
  JOIN customer c ON sa.cust_sk = c.c_customer_sk
  JOIN date_dim d ON sa.sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_fy_year = 1905
) q1
INTERSECT
SELECT
  c.c_customer_id,
  d.d_fy_year,
  hd.hd_income_band_sk,
  sa.total_profit,
  ra.total_refund,
  (
    SELECT SUM(inv_quantity_on_hand)
    FROM inventory inv
    WHERE inv.inv_item_sk = sa.item_sk
      AND inv.inv_date_sk = ra.return_date_sk
  ) AS inventory_on_refund_date
FROM sales_agg sa
JOIN returns_agg ra ON ra.cust_sk = sa.cust_sk AND ra.item_sk = sa.item_sk
JOIN customer c ON sa.cust_sk = c.c_customer_sk
JOIN date_dim d ON ra.return_date_sk = d.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1905
LIMIT 100
