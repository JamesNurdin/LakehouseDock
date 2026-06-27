WITH cs_agg AS (
  SELECT
    date_format(dd.d_date, '%Y-%m') AS month,
    i.i_category AS category,
    sum(cs.cs_quantity) AS cs_quantity,
    sum(cs.cs_ext_sales_price) AS cs_sales,
    sum(cs.cs_ext_discount_amt) AS cs_discount,
    sum(cs.cs_net_profit) AS cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY
    date_format(dd.d_date, '%Y-%m'),
    i.i_category
),
ss_agg AS (
  SELECT
    date_format(dd.d_date, '%Y-%m') AS month,
    i.i_category AS category,
    sum(ss.ss_quantity) AS ss_quantity,
    sum(ss.ss_ext_sales_price) AS ss_sales,
    sum(ss.ss_ext_discount_amt) AS ss_discount,
    sum(ss.ss_net_profit) AS ss_net_profit
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY
    date_format(dd.d_date, '%Y-%m'),
    i.i_category
),
inv_agg AS (
  SELECT
    date_format(dd.d_date, '%Y-%m') AS month,
    i.i_category AS category,
    sum(inv.inv_quantity_on_hand) AS total_inventory
  FROM inventory inv
  JOIN date_dim dd ON inv.inv_date_sk = dd.d_date_sk
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  GROUP BY
    date_format(dd.d_date, '%Y-%m'),
    i.i_category
),
promo_agg AS (
  SELECT
    date_format(dd_start.d_date, '%Y-%m') AS month,
    i.i_category AS category,
    sum(p.p_cost) AS promo_cost,
    count(distinct p.p_promo_sk) AS promo_count
  FROM promotion p
  JOIN date_dim dd_start ON p.p_start_date_sk = dd_start.d_date_sk
  JOIN item i ON p.p_item_sk = i.i_item_sk
  GROUP BY
    date_format(dd_start.d_date, '%Y-%m'),
    i.i_category
)
SELECT
  coalesce(cs.month, ss.month, inv.month, promo.month) AS month,
  coalesce(cs.category, ss.category, inv.category, promo.category) AS category,
  coalesce(cs.cs_quantity, 0) AS catalog_quantity,
  coalesce(ss.ss_quantity, 0) AS store_quantity,
  coalesce(cs.cs_quantity, 0) + coalesce(ss.ss_quantity, 0) AS total_quantity,
  coalesce(cs.cs_sales, 0) AS catalog_sales,
  coalesce(ss.ss_sales, 0) AS store_sales,
  coalesce(cs.cs_sales, 0) + coalesce(ss.ss_sales, 0) AS total_sales,
  coalesce(cs.cs_discount, 0) AS catalog_discount,
  coalesce(ss.ss_discount, 0) AS store_discount,
  coalesce(cs.cs_discount, 0) + coalesce(ss.ss_discount, 0) AS total_discount,
  coalesce(cs.cs_net_profit, 0) AS catalog_net_profit,
  coalesce(ss.ss_net_profit, 0) AS store_net_profit,
  coalesce(cs.cs_net_profit, 0) + coalesce(ss.ss_net_profit, 0) AS total_net_profit,
  coalesce(inv.total_inventory, 0) AS inventory_on_hand,
  coalesce(promo.promo_cost, 0) AS promotion_cost,
  coalesce(promo.promo_count, 0) AS promotion_count
FROM cs_agg cs
FULL OUTER JOIN ss_agg ss
  ON cs.month = ss.month AND cs.category = ss.category
FULL OUTER JOIN inv_agg inv
  ON coalesce(cs.month, ss.month) = inv.month
     AND coalesce(cs.category, ss.category) = inv.category
FULL OUTER JOIN promo_agg promo
  ON coalesce(cs.month, ss.month, inv.month) = promo.month
     AND coalesce(cs.category, ss.category, inv.category) = promo.category
ORDER BY month, category
