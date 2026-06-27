WITH combined AS (
  -- Catalog sales (filtered to male customers)
  SELECT
    i.i_category AS item_category,
    sm.sm_type AS ship_mode_type,
    cs.cs_net_paid AS sales_net_paid,
    cs.cs_quantity AS sales_quantity,
    cs.cs_ext_discount_amt AS discount_amount,
    cs.cs_net_profit AS profit,
    CAST(0 AS decimal(7,2)) AS returns_net_loss
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'

  UNION ALL

  -- Web sales (filtered to male customers)
  SELECT
    i.i_category,
    sm.sm_type,
    ws.ws_net_paid,
    ws.ws_quantity,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    CAST(0 AS decimal(7,2))
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'

  UNION ALL

  -- Catalog returns (filtered to male customers who were refunded)
  SELECT
    i.i_category,
    sm.sm_type,
    CAST(0 AS decimal(7,2)),
    CAST(0 AS integer),
    CAST(0 AS decimal(7,2)),
    CAST(0 AS decimal(7,2)),
    cr.cr_net_loss
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'
)
SELECT
  item_category,
  ship_mode_type,
  SUM(sales_net_paid) AS total_sales_net_paid,
  SUM(sales_quantity) AS total_sales_quantity,
  SUM(discount_amount) AS total_discount_amount,
  SUM(profit) - SUM(returns_net_loss) AS net_profit_after_returns,
  SUM(returns_net_loss) AS total_returns_net_loss,
  SUM(discount_amount) / NULLIF(SUM(sales_quantity), 0) AS avg_discount_per_item
FROM combined
GROUP BY item_category, ship_mode_type
ORDER BY net_profit_after_returns DESC
LIMIT 20
