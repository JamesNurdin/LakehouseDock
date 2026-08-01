WITH
  filtered_items AS (
    SELECT *
    FROM item
    WHERE i_rec_start_date > DATE '1999-01-01'
      AND i_manager_id IN (6, 13, 19, 40, 41)
      AND i_brand LIKE 'bar%'
      AND i_color IS NOT NULL
      AND i_category IS NOT NULL
      AND i_manufact IS NOT NULL
  ),
  sales_filtered AS (
    SELECT *
    FROM store_sales
    WHERE ss_ext_discount_amt > 100
      AND ss_wholesale_cost < 80
      AND ss_list_price BETWEEN 50 AND 150
      AND ss_quantity > 0
      AND ss_net_profit > 0
      AND ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss_ext_sales_price IS NOT NULL
  ),
  sales_agg AS (
    SELECT
      ss_item_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_quantity) AS total_qty,
      SUM(ss_ext_discount_amt) AS total_discount,
      CASE
        WHEN SUM(ss_ext_discount_amt) > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
      END AS discount_category
    FROM sales_filtered
    GROUP BY ROLLUP (ss_item_sk, ss_sold_date_sk)
  ),
  -- Full outer join keeps rows that exist only in one side
  full_joined AS (
    SELECT
      COALESCE(sa.ss_item_sk, fi.i_item_sk) AS item_sk,
      sa.ss_sold_date_sk,
      fi.i_brand,
      fi.i_manager_id,
      sa.total_sales,
      sa.total_qty,
      sa.discount_category
    FROM sales_agg sa
    FULL OUTER JOIN filtered_items fi
      ON sa.ss_item_sk = fi.i_item_sk
  ),
  -- Right outer join retains all rows from the dimension side (item)
  right_joined AS (
    SELECT
      COALESCE(sa.ss_item_sk, i.i_item_sk) AS item_sk,
      sa.ss_sold_date_sk,
      i.i_brand,
      i.i_manager_id,
      sa.total_sales,
      sa.total_qty,
      sa.discount_category
    FROM sales_agg sa
    RIGHT OUTER JOIN filtered_items i
      ON sa.ss_item_sk = i.i_item_sk
  ),
  -- Average sales per brand (scalar subquery used later)
  brand_avg AS (
    SELECT i_brand, AVG(total_sales) AS avg_brand_sales
    FROM full_joined
    WHERE total_sales IS NOT NULL
    GROUP BY i_brand
  ),
  ranked AS (
    SELECT
      fj.item_sk,
      fj.ss_sold_date_sk,
      fj.i_brand,
      fj.i_manager_id,
      fj.total_sales,
      fj.total_qty,
      fj.discount_category,
      ba.avg_brand_sales,
      ROW_NUMBER() OVER (PARTITION BY fj.ss_sold_date_sk ORDER BY fj.total_sales DESC) AS sales_rank,
      SUM(fj.total_sales) OVER (
        PARTITION BY fj.i_brand
        ORDER BY fj.ss_sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      ) AS moving_sales_3
    FROM full_joined fj
    LEFT JOIN brand_avg ba ON fj.i_brand = ba.i_brand
    WHERE EXISTS (
      SELECT 1 FROM sales_filtered sf
      WHERE sf.ss_item_sk = fj.item_sk
        AND sf.ss_sold_date_sk = fj.ss_sold_date_sk
    )
  ),
  top_items AS (
    SELECT item_sk FROM ranked WHERE sales_rank <= 5
  ),
  all_items AS (
    SELECT i_item_sk AS item_sk FROM item
  ),
  non_top_items AS (
    SELECT item_sk FROM all_items
    EXCEPT
    SELECT item_sk FROM top_items
  )
SELECT
  r.item_sk,
  r.ss_sold_date_sk,
  r.i_brand,
  r.i_manager_id,
  r.total_sales,
  r.total_qty,
  r.discount_category,
  r.avg_brand_sales,
  r.sales_rank,
  r.moving_sales_3,
  CASE WHEN r.item_sk IN (SELECT item_sk FROM non_top_items) THEN 'Non-Top' ELSE 'Top' END AS item_category
FROM ranked r
ORDER BY r.total_sales DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
