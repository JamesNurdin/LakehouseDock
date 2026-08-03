WITH
  sales_items AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_brand,
      i.i_category,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      p.p_promo_name,
      p.p_channel_press,
      cc.cc_name,
      sm.sm_carrier
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(p.p_promo_name, '^.*(SALE|DISCOUNT).*$')
      AND p.p_channel_press = 'N'
      AND cc.cc_name LIKE 'Call Center %'
      AND substr(i.i_product_name, 1, 5) = 'Ultra'
  ),
  returns_items AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_brand,
      i.i_category,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_refunded_cash
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '.*(Clear|Clean).*')
      AND i.i_product_name LIKE '%Pro%'
  ),
  sales_no_returns AS (
    SELECT s.*
    FROM sales_items s
    WHERE NOT EXISTS (
      SELECT 1 FROM returns_items r WHERE r.i_item_sk = s.i_item_sk
    )
  ),
  union_items AS (
    SELECT
      i_item_sk,
      i_product_name,
      i_brand,
      i_category,
      cs_quantity                AS quantity,
      cs_ext_sales_price         AS sales_amount,
      cs_net_profit              AS profit,
      p_promo_name               AS promo,
      cc_name                    AS call_center,
      sm_carrier                 AS carrier,
      NULL                       AS return_quantity,
      NULL                       AS return_amount,
      NULL                       AS refunded_cash
    FROM sales_no_returns

    UNION

    SELECT
      i_item_sk,
      i_product_name,
      i_brand,
      i_category,
      NULL                       AS quantity,
      NULL                       AS sales_amount,
      NULL                       AS profit,
      NULL                       AS promo,
      NULL                       AS call_center,
      NULL                       AS carrier,
      sr_return_quantity         AS return_quantity,
      sr_return_amt              AS return_amount,
      sr_refunded_cash           AS refunded_cash
    FROM returns_items
  ),
  sales_and_returns AS (
    SELECT s.i_item_sk
    FROM sales_items s
    JOIN returns_items r ON s.i_item_sk = r.i_item_sk
  ),
  final_set AS (
    SELECT *
    FROM union_items
    EXCEPT
    SELECT u.*
    FROM union_items u
    JOIN sales_and_returns sar ON u.i_item_sk = sar.i_item_sk
  )
SELECT
  i_brand,
  i_category,
  COUNT(DISTINCT i_item_sk)                     AS distinct_items,
  SUM(COALESCE(quantity, 0))                    AS total_quantity_sold,
  SUM(COALESCE(sales_amount, 0))                AS total_sales,
  SUM(COALESCE(profit, 0))                      AS total_profit,
  SUM(COALESCE(return_quantity, 0))            AS total_return_qty,
  SUM(COALESCE(return_amount, 0))              AS total_return_amount,
  SUM(COALESCE(refunded_cash, 0))               AS total_refunded_cash,
  MAX(promo)                                    AS example_promo,
  MAX(call_center)                              AS example_call_center,
  MAX(carrier)                                  AS example_carrier,
  CONCAT(i_brand, '-', i_category)             AS brand_category_combined
FROM final_set
GROUP BY GROUPING SETS (
    (i_brand, i_category),
    (i_brand),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
