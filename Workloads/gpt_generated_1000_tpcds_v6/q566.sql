WITH
  store_part AS (
    SELECT
      d.d_year,
      i.i_category,
      cd.cd_gender,
      ss.ss_net_paid AS total_sales,
      'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                              AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                              AND cs.cs_item_sk = i.i_item_sk
                              AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_type = 'review'
    )
      AND d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND ss.ss_quantity > 1
  ),
  catalog_part AS (
    SELECT
      d.d_year,
      i.i_category,
      cd.cd_gender,
      cs.cs_net_paid AS total_sales,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
                              AND d.d_date_sk = inv.inv_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_type = 'review'
    )
      AND d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND cs.cs_quantity > 2
  ),
  unioned AS (
    SELECT d_year, i_category, cd_gender, total_sales, channel FROM store_part
    UNION ALL
    SELECT d_year, i_category, cd_gender, total_sales, channel FROM catalog_part
  ),
  final_agg AS (
    SELECT
      d_year,
      i_category,
      cd_gender,
      channel,
      SUM(total_sales) AS sum_sales,
      COUNT(*) AS txn_count
    FROM unioned
    GROUP BY ROLLUP (d_year, i_category, cd_gender), channel
    HAVING SUM(total_sales) > 1000
  )
SELECT
  d_year,
  i_category,
  cd_gender,
  channel,
  sum_sales,
  txn_count,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_sales DESC) AS yearly_rank
FROM final_agg
ORDER BY d_year DESC, sum_sales DESC
LIMIT 100
