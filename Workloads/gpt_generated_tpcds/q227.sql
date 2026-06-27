WITH
  sales_agg AS (
    SELECT
      i.i_category          AS category,
      cd.cd_gender          AS gender,
      SUM(cs.cs_quantity)  AS total_qty_sold,
      SUM(cs.cs_ext_sales_price) AS total_sales_amount,
      SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
      SUM(cs.cs_net_paid)  AS total_net_paid,
      SUM(cs.cs_net_profit) AS total_profit
    FROM
      catalog_sales cs
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY
      i.i_category,
      cd.cd_gender
  ),
  returns_agg AS (
    SELECT
      i.i_category          AS category,
      cd.cd_gender          AS gender,
      SUM(cr.cr_return_quantity) AS total_qty_returned,
      SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
      SUM(cr.cr_net_loss)   AS total_return_loss
    FROM
      catalog_returns cr
      JOIN item i ON cr.cr_item_sk = i.i_item_sk
      JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY
      i.i_category,
      cd.cd_gender
  )
SELECT
  s.category,
  s.gender,
  s.total_qty_sold,
  s.total_sales_amount,
  COALESCE(r.total_qty_returned, 0)      AS total_qty_returned,
  COALESCE(r.total_return_amount, 0)    AS total_return_amount,
  s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_amount,
  s.total_profit - COALESCE(r.total_return_loss, 0)       AS net_profit,
  COALESCE(r.total_qty_returned, 0) / NULLIF(s.total_qty_sold, 0) AS return_rate
FROM
  sales_agg s
  LEFT JOIN returns_agg r
    ON s.category = r.category
   AND s.gender   = r.gender
ORDER BY
  net_sales_amount DESC
LIMIT 10
